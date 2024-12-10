import express from 'express';
import userRoutes from './routes/userRoutes';
import questionRoutes from './routes/questionRoutes';
import userStatsRoutes from './routes/userStatsRoutes';
import { PrismaClient } from '@prisma/client';
import { readJSON } from './services/jsonService';

const app = express();
const prisma = new PrismaClient();

app.use(express.json());

app.use('/users', userRoutes);
app.use('/questions', questionRoutes);
app.use('/user-stats', userStatsRoutes);

const syncJSONToDatabase = async () => {
    const users = await readJSON('users.json');
    if (typeof users.users === 'object' && users.users !== null) {
        for (const [username, password] of Object.entries(users.users as Record<string, string>)) {
            await prisma.user.upsert({
                where: { username },
                update: {},
                create: { username, password },
            });
        }
    }

    const questions = await readJSON('questions.json');
    if (Array.isArray(questions.questions)) {
        for (const questionData of questions.questions) {
            const { question, answers, correctAnswerIndex } = questionData;

            const existingQuestion = await prisma.question.findUnique({
                where: { question },
            });

            if (!existingQuestion) {
                await prisma.question.create({
                    data: { question, answers, correctAnswerIndex },
                });
            }
        }
    }

    const userStats = await readJSON('user_stats.json');
    if (typeof userStats.users === 'object' && userStats.users !== null) {
        for (const [username, stats] of Object.entries(userStats.users as Record<string, { victories: number }>)) {
            await prisma.userStats.upsert({
                where: { username },
                update: { victories: stats.victories, totalGames: userStats.total_games },
                create: { username, victories: stats.victories, totalGames: userStats.total_games },
            });
        }
    }
};

syncJSONToDatabase()
    .then(() => console.log('Database synchronized with JSON files.'))
    .catch((err) => console.error('Error synchronizing database:', err));

app.listen(3000, () => console.log('Server running on port 3000'));
