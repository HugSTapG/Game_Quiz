import { PrismaClient } from '@prisma/client';
import { readJSON, writeJSON } from './jsonService';

const prisma = new PrismaClient();
const statsFile = 'user_stats.json';

export const getUserStats = async (username: string) => {
    const stats = await prisma.userStats.findUnique({
        where: { username },
    });

    return stats;
};


export const updateUserStats = async (username: string, victories: number, totalGames: number) => {
    const updatedStats = await prisma.userStats.upsert({
        where: { username },
        update: { victories, totalGames },
        create: { username, victories, totalGames },
    });

    const stats = await readJSON(statsFile);
    if (typeof stats.users === 'object' && stats.users !== null) {
        stats.users[username] = { victories, totalGames };
        stats.total_games += 1;
        await writeJSON(statsFile, stats);
    }

    return updatedStats;
};
