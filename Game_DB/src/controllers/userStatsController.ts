import { Request, Response } from 'express';
import { updateUserStats } from '../services/userStatsService';

export const updateStats = async (req: Request, res: Response) => {
  const { username, ...stats } = req.body;
  
  try {
    const updatedStats = await updateUserStats(username, stats);
    res.json(updatedStats);
  } catch (error) {
    res.status(500).json({ message: 'Error updating user stats', error });
  }
};