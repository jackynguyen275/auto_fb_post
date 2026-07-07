const admin = require('firebase-admin');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// Khởi tạo Firebase từ biến môi trường
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Khởi tạo AI
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

async function main() {
    const now = new Date();
    console.log("Kiểm tra bài cần đăng lúc:", now.toLocaleString("vi-VN", { timeZone: "Asia/Ho_Chi_Minh" }));

    // Lấy các bài đến giờ đăng nhưng chưa đăng
    const snapshot = await db.collection('scheduled_posts')
        .where('scheduledAt', '<=', now.toISOString())
        .where('isPosted', '==', false)
        .limit(10)
        .get();

    if (snapshot.empty) {
        console.log("Không có bài nào cần đăng.");
        return;
    }

    console.log(`Tìm thấy ${snapshot.size} bài cần xử lý`);

    for (const doc of snapshot.docs) {
        const data = doc.data();
        try {
            console.log("Đang xử lý dự án:", data.projectName);

            // 1. Tạo nội dung AI
            const prompt = `
        Tạo bài đăng Fanpage hấp dẫn cho dự án: ${data.projectName}.
        Thông tin dự án: ${data.description}.
        Đối tượng: Người dân, khách hàng tại Thành phố Hồ Chí Minh.
        Ngôn ngữ: Tiếng Việt tự nhiên, thân thiện.
        Không quá 300 từ, có lời kêu gọi hành động phù hợp.
      `;
            const result = await model.generateContent(prompt);
            const content = result.response.text();
            console.log("✅ Đã tạo nội dung xong");

            // 2. Đăng lên Fanpage
            await axios.post(`https://graph.facebook.com/v25.0/${data.pageId}/feed`, null, {
                params: { message: content, access_token: data.pageToken }
            });
            console.log("✅ Đăng bài thành công lên Fanpage:", data.pageName);

            // 3. Đánh dấu đã đăng
            await doc.ref.update({
                isPosted: true,
                postedAt: new Date().toISOString(),
                generatedContent: content
            });

        } catch (err) {
            console.error("❌ Lỗi dự án", data.projectName, ":", err.response?.data || err.message);
            await doc.ref.update({ lastError: err.message });
        }
    }
}

main().then(() => process.exit(0)).catch(err => {
    console.error("Lỗi tổng thể:", err);
    process.exit(1);
});