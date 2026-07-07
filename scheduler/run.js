const admin = require('firebase-admin');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} catch (e) {
    console.error("❌ Lỗi đọc khóa Firebase: Kiểm tra lại định dạng Secret nhé!");
    process.exit(1);
}

const db = admin.firestore();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

async function main() {
    const now = new Date();
    console.log("Kiểm tra lúc:", now.toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" }));

    const snapshot = await db.collection('scheduled_posts')
        .where('scheduledAt', '<=', now.toISOString())
        .where('isPosted', '==', false)
        .limit(10)
        .get();

    if (snapshot.empty) return console.log("✅ Không có bài nào cần đăng");

    console.log(`Tìm thấy ${snapshot.size} bài`);
    for (const doc of snapshot.docs) {
        const data = doc.data();
        try {
            // Lấy thông tin dự án nếu thiếu
            let projectData = data;
            if (!data.pageId) {
                const projSnap = await db.collection('projects').doc(data.projectId).get();
                if (!projSnap.exists) throw new Error("Không tìm thấy dự án");
                projectData = { ...projSnap.data(), ...data };
            }

            // Tạo nội dung AI
            const prompt = `Tạo bài Fanpage cho dự án: ${projectData.name || projectData.projectName}. Mô tả: ${projectData.description}. Đối tượng TPHCM, tiếng Việt thân thiện.`;
            const content = (await model.generateContent(prompt)).response.text();

            // Đăng bài
            await axios.post(`https://graph.facebook.com/v25.0/${projectData.pageId}/feed`, null, {
                params: { message: content, access_token: projectData.pageToken }
            });

            // Cập nhật trạng thái
            await doc.ref.update({ isPosted: true, postedAt: new Date().toISOString() });
            console.log(`✅ Đăng thành công: ${projectData.name || projectData.projectName}`);
        } catch (err) {
            console.error(`❌ Lỗi: ${err.response?.data?.error?.message || err.message}`);
            await doc.ref.update({ lastError: err.message });
        }
    }
}

main().then(() => process.exit(0)).catch(err => {
    console.error("❌ Lỗi tổng thể:", err);
    process.exit(1);
});