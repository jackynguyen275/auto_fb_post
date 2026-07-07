const admin = require('firebase-admin');
const functions = require('firebase-functions');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

admin.initializeApp();
const db = admin.firestore();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash" });

// Hàm chạy tự động mỗi phút kiểm tra bài cần đăng
exports.checkAndPostScheduled = functions.pubsub.schedule('every 1 minutes')
    .timeZone('Asia/Ho_Chi_Minh')
    .onRun(async (context) => {
        const now = new Date();
        const snapshot = await db.collection('scheduled_posts')
            .where('scheduledAt', '<=', now)
            .where('isPosted', '==', false)
            .get();

        for (const doc of snapshot.docs) {
            const data = doc.data();
            try {
                // Tạo nội dung mới với AI
                const prompt = `Tạo bài đăng Fanpage cho dự án: ${data.projectName}. Mô tả: ${data.description}. Phù hợp với thị trường TPHCM.`;
                const result = await model.generateContent(prompt);
                const content = result.response.text();

                // Đăng lên Fanpage
                await axios.post(`https://graph.facebook.com/v25.0/${data.pageId}/feed`, null, {
                    params: { message: content, access_token: data.pageToken }
                });

                // Đánh dấu đã đăng
                await doc.ref.update({ isPosted: true, postedAt: new Date() });
                console.log(`Đăng bài thành công cho dự án ${data.projectName}`);
            } catch (err) {
                console.error(`Lỗi đăng bài: ${err.message}`);
            }
        }
        return null;
    });