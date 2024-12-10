import { Request, Response } from 'express';
import { getQuestions, addQuestion } from '../services/questionService';

export const getAllQuestions = async (req: Request, res: Response) => {
    const questions = await getQuestions();
    res.json(questions);
};

export const createQuestion = async (req: Request, res: Response) => {
    const { question, answers, correctAnswerIndex } = req.body;
    const newQuestion = await addQuestion(question, answers, correctAnswerIndex);
    res.status(201).json(newQuestion);
};
