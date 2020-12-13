const express = require('express');
const Web3 = require('web3');
const port = process.env.port || 3000;
const HDWalletProvider = require('truffle-hdwallet-provider');
const path = require('path');
const app = express();
const bodyParser = require('body-parser');
const fs = require('fs');

//const moment = require('moment');

app.get('/', function(req, res){
    //let myDate = moment('2020-11-09 18:30').unix();
    //let unixDate = moment.unix(1604959520).format('DD/MM/YYYY hh:mm:ss');
    //res.send(myDate.toString());
    //res.send(unixDate.toString());
    res.send('Hello world');
});

const credentialPath = path.resolve(process.cwd(), 'credentials.json');;
const credentials = JSON.parse(fs.readFileSync(credentialPath, 'utf8'));
const seedPhrase_MNEMONIC = credentials.seedPhrase;
const infuraAccessPoint = credentials.accessPoint;

const ganacheProvider = new Web3.providers.HttpProvider('http://127.0.0.1:7545');
//const infuraProvider = new HDWalletProvider(seedPhrase_MNEMONIC, infuraAccessPoint, 0, 3);

//web3 = new Web3(infuraProvider);
web3 = new Web3(ganacheProvider);

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
const contractRoute = require('./routes/contract.route');
app.use('/api/contract', contractRoute);
app.listen(port, ()=> console.log('Listening on port 3000'));