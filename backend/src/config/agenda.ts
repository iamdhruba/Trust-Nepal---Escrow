import Agenda from 'agenda';

let agenda: Agenda | null = null;

export const getAgenda = () => {
  if (!agenda) {
    agenda = new Agenda({
      db: { address: process.env.MONGO_URI || 'mongodb://localhost:27017/trustnepal' },
      processEvery: '30 seconds',
    });
  }
  return agenda;
};

export const initAgenda = async () => {
  const instance = getAgenda();
  await instance.start();
  console.log('Agenda background scheduler initialized');
};
