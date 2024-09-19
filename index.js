// index.js

const { mage } =  require('./src/mage.js');
const { activate } =  require('./src/bot.js');

//System Admin Methods
const path = require('path');
const fs = require('fs');

// Set up express app
const express = require('express');
const bodyParser = require('body-parser');
const app = express();
app.use(bodyParser.json());


app.listen( () => {
    console.log(`Starting up Maple bot`);
    activate();
});