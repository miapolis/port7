export const secondsLeft = (time: number): number => {
  return Math.ceil(Math.max(0, time - Date.now()) / 1000);
};
