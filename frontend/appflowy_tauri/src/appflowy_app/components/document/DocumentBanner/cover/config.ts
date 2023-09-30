export const colors = ['#e1fbff', '#defff1', '#ddffd6', '#f5ffdc', '#fff2cd', '#ffefe3', '#ffe7ee', '#e8e0ff'];

export const randomColor = () => {
  return colors[Math.floor(Math.random() * colors.length)];
};
