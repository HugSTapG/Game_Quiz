import express from 'express';
import { updateStats } from '../controllers/userStatsController';
import { getUserStats } from '../services/userStatsService';

const router = express.Router();

router.put('/', updateStats);

router.get('/:username', async (req, res) => {
    const { username } = req.params;

    try {
        const stats = await getUserStats(username);

        if (stats) {
            res.json(stats);
        } else {
            res.status(404).json({ message: `User ${username} not found.` });
        }
    } catch (error) {
        res.status(500).json({ message: 'Error retrieving user stats.', error });
    }
});

export default router;
