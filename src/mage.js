const fs = require('fs')
const { doSomething } = require('./utils.js');


async function mage(req, res) {

    console.log("Running Contact Sheet");

    await move();
}

async function move() {
    console.log("launching ahk script")   
}

module.exports = {
    mage
};