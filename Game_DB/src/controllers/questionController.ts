import { Request, Response } from 'express';
import { 
    getQuestions, 
    addQuestion, 
    updateQuestionSubject, 
    syncQuestionsBySubject, 
    syncAllQuestionsToJSON,
    forceSyncDBToJSON,
    getAllQuestionsFromDB
} from '../services/questionService';

export const getAllQuestions = async (req: Request, res: Response) => {
    try {
        const { subject } = req.query;
        const questions = await getQuestions(subject as string);
        res.json(questions);
    } catch (error) {
        res.status(500).json({ message: 'Error retrieving questions', error });
    }
};

export const getAllQuestionsDB = async (req: Request, res: Response) => {
    try {
        const questions = await getAllQuestionsFromDB();
        res.json(questions);
    } catch (error) {
        res.status(500).json({ message: 'Error retrieving questions from database', error });
    }
};

export const createQuestion = async (req: Request, res: Response) => {
    try {
        const { question, answers, correctAnswerIndex, subject } = req.body;
        const newQuestion = await addQuestion(question, answers, correctAnswerIndex, subject);
        res.status(201).json(newQuestion);
    } catch (error) {
        res.status(500).json({ message: 'Error creating question', error });
    }
};

export const updateSubject = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { subject } = req.body;
        const updatedQuestion = await updateQuestionSubject(Number(id), subject);
        res.json(updatedQuestion);
    } catch (error) {
        res.status(500).json({ message: 'Error updating question subject', error });
    }
};

export const syncBySubject = async (req: Request, res: Response) => {
    try {
        const { subject } = req.params;
        const questions = await syncQuestionsBySubject(subject);
        res.json({ 
            message: `Questions synced for subject: ${subject}`, 
            questions 
        });
    } catch (error) {
        res.status(500).json({ message: 'Error syncing questions by subject', error });
    }
};

export const syncAllQuestions = async (req: Request, res: Response) => {
    try {
        const questions = await syncAllQuestionsToJSON();
        res.json({ 
            message: 'All questions synced to JSON', 
            questions 
        });
    } catch (error) {
        res.status(500).json({ message: 'Error syncing all questions', error });
    }
};

export const forceSync = async (req: Request, res: Response) => {
    try {
        await forceSyncDBToJSON();
        res.json({ message: 'Database forcefully synchronized with JSON file' });
    } catch (error) {
        res.status(500).json({ message: 'Error in force sync', error });
    }
};