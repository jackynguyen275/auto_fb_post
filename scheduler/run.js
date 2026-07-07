const admin = require('firebase-admin');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

console.log("🔹 Bắt đầu khởi tạo...");

// Kiểm tra biến môi trường
if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.error("❌ Thiếu biến FIREBASE_SERVICE_ACCOUNT!");
    process.exit(1);
}
if (!process.env.GEMINI_API_KEY) {
    console.error("❌ Thiếu biến GEMINI_API_KEY!");
    process.exit(1);
}

// Khởi tạo Firebase
try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: "https://autofbpost1-default-rtdb.asia-southeast1.firebasedatabase.app"
    });
    console.log("✅ Khởi tạo Firebase thành công");
} catch (err) {
    console.error("❌ Lỗi khởi tạo Firebase:", err.message);
    process.exit(1);
}

const db = admin.database();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

async function main() {
    const now = new Date();
    console.log(`\n🔹 Kiểm tra bài cần đăng lúc: ${now.toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })}`);

    try {
        const snapshot = await db.ref('scheduled_posts')
            .orderByChild('scheduledAt')
            .endAt(now.toISOString())
            .once('value');

        if (!snapshot.exists()) {
            console.log("✅ Không có bài nào cần đăng, kết thúc.");
            return;
        }

        const posts = snapshot.val();
        const needProcess = Object.entries(posts).filter(([_, post]) => !post.isPosted);
        if (needProcess.length === 0) {
            console.log("✅ Tất cả bài đã đăng, kết thúc.");
            return;
        }

        console.log(`📋 Tìm thấy ${needProcess.length} bài cần xử lý`);

        for (const [postId, data] of needProcess) {
            try {
                console.log(`\n🔹 Xử lý bài ID: ${postId}`);

                // Lấy thông tin đầy đủ
                let projectInfo = data;
                if (!data.pageId || !data.pageToken) {
                    console.log("🔹 Lấy thông tin dự án...");
                    const projSnap = await db.ref(`projects/${data.projectId}`).once('value');
                    if (!projSnap.exists()) throw new Error("Không tìm thấy dự án");
                    projectInfo = { ...projSnap.val(), ...data };
                }

                // Tạo nội dung AI
                console.log("🔹 Đang tạo nội dung...");
                const prompt = `Tạo bài Fanpage cho dự án: ${projectInfo.name || projectInfo.projectName}. Mô tả: ${projectInfo.description}. Đối tượng TPHCM, tiếng Việt thân thiện.`;
                const content = (await model.generateContent(prompt)).response.text();
                console.log("✅ Tạo nội dung thành công");

                // Đăng bài
                console.log("🔹 Đang đăng bài...");
                await axios.post(
                    `https://graph.facebook.com/v25.0/${projectInfo.pageId}/feed`,
                    null,
                    { params: { message: content, access_token: projectInfo.pageToken } }
                );
                console.log("✅ Đăng bài thành công!");

                // Cập nhật trạng thái
                await db.ref(`scheduled_posts/${postId}`).update({
                    isPosted: true,
                    postedAt: new Date().toISOString(),
                    generatedContent: content
                });
                console.log("✅ Cập nhật trạng thái thành công");

            } catch (err) {
                console.error("❌ Lỗi xử lý bài:", err.response?.data?.error?.message || err.message);
                await db.ref(`scheduled_posts/${postId}`).update({ lastError: err.message });
            }
        }

    } catch (dbErr) {
        console.error("❌ Lỗi truy vấn CSDL:", dbErr.message);
        process.exit(1);
    }
}

main()
    .then(() => {
        console.log("\n✅ Hoàn tất quá trình!");
        process.exit(0);
    })
    .catch((fatalErr) => {
        console.error("\n❌ Lỗi nghiêm trọng:", fatalErr);
        process.exit(1);
    });