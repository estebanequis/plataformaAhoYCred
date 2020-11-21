const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');

router.get('/compile', function(req, res){
    try{
        contractService.compile();
        res.status(200).send('Contract compiled');
    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/deploy', function(req, res){
    try{
        contractService.deploy();
        res.status(200).send('Contract deployed');
    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/sum', async function(req, res){
    try{
        const contract = contractService.getContract();
        
        let result = await contract.methods.sum(1, 3).call()
        .then(function(result){
            res.status(200).send('Result:' + result);
        });

    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/getIndex', async function(req, res){
    try{
        const contract = contractService.getContract();
        let result = await contract.methods.index().call();
        res.status(200).send('Event index:' + result);
    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/publishEvent', async function(req, res){
    try{
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.publishEvent('My first event').send({
            from:accounts[0]
        });
        res.status(200).send('Event published.');
    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/getPublishedEvent', async function(req, res){
    try{
        const contract = contractService.getContract();
        let eventMethodName = 'messageEvent(uint,string)';
        let filterEventMethod = web3.utils.sha3(eventMethodName);
        let indexInEvent = web3.utils.padLeft(web3.utils.toHex(1), 64);

        let filters = {
            address: contract._address,
            fromBlock: "0x1",
            toBlock: "latest",
            topics: [filterEventMethod, indexInEvent]
        }

        let result = await web3.eth.getPastLogs(filters);
        res.status(200).send('Event message:' + web3.eth.util.hexToUtf8(result[0].data));
    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/getBalnce', async function(req, res){
    try{
        const contract = contractService.getContract();
        let result = await contract.methods.getBalance().call();
        res.status(200).send('Balance:' + web3.utils.fromWei(result, 'ether') + ' ethers');
    } catch(error){
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/probarRetorno', async function(req, res){
    try{
        const contract = contractService.getContract();
        let result = await contract.methods.probarRetorno(6).call();
        res.status(200).send('Retorno:' + result);
    } catch(error){
        console.log(error);
        res.status(500).send(error.data);
    }
});

module.exports = router;