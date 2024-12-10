import { PrismaClient } from '@prisma/client';
import { readJSON, writeJSON } from './jsonService';

const prisma = new PrismaClient();
const usersFile = 'users.json';

export const getUsers = async () => {
    return await readJSON(usersFile);
};

export const addUser = async (username: string, password: string) => {
    const newUser = await prisma.user.create({
        data: { username, password },
    });

    const users = await readJSON(usersFile);
    if (typeof users.users === 'object' && users.users !== null) {
        users.users[username] = password;
        await writeJSON(usersFile, users);
    }

    return newUser;
};
