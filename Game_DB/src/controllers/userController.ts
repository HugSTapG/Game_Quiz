import { Request, Response } from 'express';
import { getUsers, addUser } from '../services/userService';

export const getAllUsers = async (req: Request, res: Response) => {
    const users = await getUsers();
    res.json(users);
};

export const createUser = async (req: Request, res: Response) => {
    const { username, password } = req.body;
    const newUser = await addUser(username, password);
    res.status(201).json(newUser);
};
