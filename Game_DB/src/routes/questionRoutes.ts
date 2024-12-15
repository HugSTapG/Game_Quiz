import express from 'express';
import {
    getAllQuestions,
    getAllQuestionsDB,
    createQuestion,
    updateSubject,
    syncBySubject,
    syncAllQuestions
    } from '../controllers/questionController';

const router = express.Router();

router.get('/', getAllQuestions);
router.get('/db', getAllQuestionsDB);
router.post('/', createQuestion);
router.patch('/:id/subject', updateSubject);
router.post('/sync/subject/:subject', syncBySubject);
router.post('/sync/all', syncAllQuestions);

export default router;