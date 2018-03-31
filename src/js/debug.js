/*
    Debug functions
*/

// const globals = nodeRequire('./js/globals');
const misc = nodeRequire('./js/misc');

module.exports = () => {
    const randNum = misc.getRandomNumber(1, 8);
    misc.playSound(`no/no${randNum}`);
};
