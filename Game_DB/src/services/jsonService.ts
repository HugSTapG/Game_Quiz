import fs from 'fs/promises';
import path from 'path';

const gameFolder = path.resolve(__dirname, '../../game');

export const readJSON = async (filename: string): Promise<any> => {
    const filePath = path.join(gameFolder, filename);
    const data = await fs.readFile(filePath, 'utf-8');
    return JSON.parse(data);
};

export const writeJSON = async (filename: string, content: any): Promise<void> => {
    const filePath = path.join(gameFolder, filename);
    await fs.writeFile(filePath, JSON.stringify(content, null, 2));
};
