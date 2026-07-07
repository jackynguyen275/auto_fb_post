const admin = require('firebase-admin');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

console.log("🔹 Bắt đầu khởi tạo...");

// Kiểm tra biến môi trường bắt buộc
if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
    console.error("❌ Thiếu biến FIREBASE_SERVICE_ACCOUNT trong Secrets!");
    process.exit(1);
}
if (!process.env.GEMINI_API_KEY) {
    console.error("❌ Thiếu biến GEMINI_API_KEY trong Secrets!");
    process.exit(1);
}

// Khởi tạo Firebase có bắt lỗi
try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    console.log("✅ Khởi tạo Firebase thành công");
} catch (err) {
    console.error("❌ Lỗi khởi tạo Firebase:", err.message);
    console.error("💡 Kiểm tra lại định dạng JSON của khóa trong Secrets nhé!");
    process.exit(1);
}

const db = admin.firestore();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

async function main() {
    const now = new Date();
    console.log(`\n🔹 Kiểm tra bài cần đăng lúc: ${now.toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" })}`);

    try {
        const snapshot = await db.collection('scheduled_posts')
            .where('scheduledAt', '<=', now.toISOString())
            .where('isPosted', '==', false)
            .limit(10)
            .get();

        if (snapshot.empty) {
            console.log("✅ Không có bài nào cần đăng, kết thúc.");
            return;
        }

        console.log(`📋 Tìm thấy ${snapshot.size} bài cần xử lý`);

        for (const doc of snapshot.docs) {
            const data = doc.data();
            console.log(`\n🔹 Xử lý bài ID: ${doc.id}`);

            try {
                // Lấy thông tin đầy đủ từ dự án nếu thiếu
                let projectInfo = data;
                if (!data.pageId || !data.pageToken) {
                    console.log("🔹 Thiếu thông tin Fanpage, lấy từ dự án...");
                    const projectSnap = await db.collection('projects').doc(data.projectId).get();
                    if (!projectSnap.exists) throw new Error("Không tìm thấy thông tin dự án");
                    projectInfo = { ...projectSnap.data(), ...data };
                }

                // Tạo nội dung AI
                console.log("🔹 Đang tạo nội dung với AI...");
                const prompt = `
Tạo bài đăng Fanpage hấp dẫn cho dự án: ${projectInfo.name || projectInfo.projectName}.
Thông tin chi tiết: ${projectInfo.description}.
Đối tượng khách hàng: Người dân, doanh nghiệp tại Thành phố Hồ Chí Minh.
Ngôn ngữ: Tiếng Việt tự nhiên, thân thiện, phù hợp nội dung marketing.
        `;
                const aiResult = await model.generateContent(prompt);
                const content = aiResult.response.text();
                console.log("✅ Tạo nội dung thành công");

                // Đăng lên Fanpage
                console.log("🔹 Đang đăng bài lên Fanpage...");
                await axios.post(
                    `https://graph.facebook.com/v25.0/${projectInfo.pageId}/feed`,
                    null,
                    { params: { message: content, access_token: projectInfo.pageToken } }
                );
                console.log("✅ Đăng bài lên Fanpage thành công!");

                // Cập nhật trạng thái
                await doc.ref.update({
                    isPosted: true,
                    postedAt: new Date().toISOString(),
                    generatedContent: content
                });
                console.log("✅ Cập nhật trạng thái bài đăng thành công");

            } catch (err) {
                console.error("❌ Lỗi xử lý bài:", err.response?.data?.error?.message || err.message);
                await doc.ref.update({ lastError: err.message });
            }
        }

    } catch (dbErr) {
        console.error("❌ Lỗi truy vấn Firestore:", dbErr.message);
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