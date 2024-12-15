import { PrismaClient } from '@prisma/client';
import { readJSON, writeJSON } from './jsonService';

const prisma = new PrismaClient();
const statsFile = 'user_stats.json';

interface UserStats {
  averageAnswerTime: number;
  bestWinStreak: number;
  correctAnswers: number;
  fastestWinTime: number;
  incorrectAnswers: number;
  totalGamesPlayed: number;
  totalPenalties: number;
  totalQuestionsAnswered: number;
  victories: number;
  winStreak: number;
}

export const getUserStats = async (username: string) => {
  const stats = await prisma.userStats.findUnique({
    where: { username },
  });
  return stats;
};

export const updateUserStats = async (username: string, stats: Partial<UserStats>) => {
  const updatedStats = await prisma.userStats.upsert({
    where: { username },
    update: {
      averageAnswerTime: stats.averageAnswerTime,
      bestWinStreak: stats.bestWinStreak,
      correctAnswers: stats.correctAnswers,
      fastestWinTime: stats.fastestWinTime,
      incorrectAnswers: stats.incorrectAnswers,
      totalGamesPlayed: stats.totalGamesPlayed,
      totalPenalties: stats.totalPenalties,
      totalQuestionsAnswered: stats.totalQuestionsAnswered,
      victories: stats.victories,
      winStreak: stats.winStreak,
    },
    create: {
      username,
      averageAnswerTime: stats.averageAnswerTime ?? 0,
      bestWinStreak: stats.bestWinStreak ?? 0,
      correctAnswers: stats.correctAnswers ?? 0,
      fastestWinTime: stats.fastestWinTime ?? 0,
      incorrectAnswers: stats.incorrectAnswers ?? 0,
      totalGamesPlayed: stats.totalGamesPlayed ?? 0,
      totalPenalties: stats.totalPenalties ?? 0,
      totalQuestionsAnswered: stats.totalQuestionsAnswered ?? 0,
      victories: stats.victories ?? 0,
      winStreak: stats.winStreak ?? 0,
    },
  });

  const jsonStats = await readJSON(statsFile);
  if (typeof jsonStats.users === 'object' && jsonStats.users !== null) {
    jsonStats.users[username] = {
      average_answer_time: stats.averageAnswerTime,
      best_win_streak: stats.bestWinStreak,
      correct_answers: stats.correctAnswers,
      fastest_win_time: stats.fastestWinTime,
      incorrect_answers: stats.incorrectAnswers,
      total_games_played: stats.totalGamesPlayed,
      total_penalties: stats.totalPenalties,
      total_questions_answered: stats.totalQuestionsAnswered,
      victories: stats.victories,
      win_streak: stats.winStreak,
    };
    await writeJSON(statsFile, jsonStats);
  }

  return updatedStats;
};