const express = require('express');
const Web3 = require('web3');
const port = process.env.port || 3000;
const app = express();

const moment = require('moment');

app.get('/', function(req, res){
    //let myDate = moment('2020-11-09 18:30').unix();
    //let unixDate = moment.unix(1604959520).format('DD/MM/YYYY hh:mm:ss');
    //res.send(myDate.toString());
    //res.send(unixDate.toString());
    res.send('Hello world');
});

const ganacheProvider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');

web3 = new Web3(ganacheProvider);

const contractRoute = require('./routes/contract.route');
app.use('/api/contract', contractRoute);

app.listen(port, ()=> console.log('Listening on port 3000'));