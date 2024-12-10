import { Request, Response } from 'express';
import { updateUserStats } from '../services/userStatsService';

export const updateStats = async (req: Request, res: Response) => {
    const { username, victories, totalGames } = req.body;
    const updatedStats = await updateUserStats(username, victories, totalGames);
    res.json(updatedStats);
};
