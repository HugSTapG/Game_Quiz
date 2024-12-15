import { PrismaClient } from '@prisma/client';
import { readJSON, writeJSON } from './jsonService';

const prisma = new PrismaClient();
const questionsFile = 'questions.json';

export const getQuestions = async (subject?: string) => {
    if (subject) {
        return await prisma.question.findMany({
            where: { subject }
        });
    }
    return await readJSON(questionsFile);
};

export const getAllQuestionsFromDB = async () => {
    return await prisma.question.findMany({
        orderBy: {
            id: 'asc'
        }
    });
};

export const addQuestion = async (question: string, answers: string[], correctAnswerIndex: number, subject: string = "General") => {
    const newQuestion = await prisma.question.create({
        data: {
            question,
            answers,
            correctAnswerIndex,
            subject
        },
    });

    const questions = await readJSON(questionsFile);
    if (Array.isArray(questions.questions)) {
        questions.questions.push({ question, answers, correctAnswerIndex });
        await writeJSON(questionsFile, questions);
    }

    return newQuestion;
};

export const updateQuestionSubject = async (questionId: number, subject: string) => {
    const updatedQuestion = await prisma.question.update({
        where: { id: questionId },
        data: { subject }
    });

    return updatedQuestion;
};

export const syncQuestionsBySubject = async (subject: string) => {
    const dbQuestions = await prisma.question.findMany({
        where: { subject }
    });

    const jsonQuestions = {
        questions: dbQuestions.map(({ question, answers, correctAnswerIndex }) => ({
            question,
            answers,
            correctAnswerIndex
        }))
    };

    await writeJSON(questionsFile, jsonQuestions);
    return jsonQuestions;
};

export const syncAllQuestionsToJSON = async () => {
    const dbQuestions = await prisma.question.findMany();

    const jsonQuestions = {
        questions: dbQuestions.map(({ question, answers, correctAnswerIndex }) => ({
            question,
            answers,
            correctAnswerIndex
        }))
    };

    await writeJSON(questionsFile, jsonQuestions);
    return jsonQuestions;
};

export const forceSyncDBToJSON = async () => {
    await syncAllQuestionsToJSON();
};