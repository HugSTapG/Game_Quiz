import { PrismaClient } from '@prisma/client';
import { readJSON, writeJSON } from './jsonService';

const prisma = new PrismaClient();
const questionsFile = 'questions.json';

export const getQuestions = async () => {
    return await readJSON(questionsFile);
};

export const addQuestion = async (question: string, answers: string[], correctAnswerIndex: number) => {
    const newQuestion = await prisma.question.create({
        data: { question, answers, correctAnswerIndex },
    });

    const questions = await readJSON(questionsFile);
    if (Array.isArray(questions.questions)) {
        questions.questions.push({ question, answers, correctAnswerIndex });
        await writeJSON(questionsFile, questions);
    }

    return newQuestion;
};
