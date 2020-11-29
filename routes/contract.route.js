const express = require('express');
const router = express.Router();
const contractService = require('../services/contract.service');

router.get('/compile', function (req, res) {
    try {
        contractService.compile();
        res.status(200).send('Contract compiled');
    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/deploy', function (req, res) {
    try {
        contractService.deploy();
        res.status(200).send('Contract deployed');
    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/sum', async function (req, res) {
    try {
        const contract = contractService.getContract();

        let result = await contract.methods.sum(1, 3).call()
            .then(function (result) {
                res.status(200).send('Result:' + result);
            });

    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/getIndex', async function (req, res) {
    try {
        const contract = contractService.getContract();
        let result = await contract.methods.index().call();
        res.status(200).send('Event index:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/publishEvent', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.publishEvent('My first event').send({
            from: accounts[0]
        });
        res.status(200).send('Event published.');
    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/getPublishedEvent', async function (req, res) {
    try {
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
    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/getBalnce', async function (req, res) {
    try {
        const contract = contractService.getContract();
        let result = await contract.methods.getBalance().call();
        res.status(200).send('Balance:' + web3.utils.fromWei(result, 'ether') + ' ethers');
    } catch (error) {
        console.log(error);
        res.status(500).send(error);
    }
});

router.get('/probarRetorno', async function (req, res) {
    try {
        const contract = contractService.getContract();
        let result = await contract.methods.probarRetorno(6).call();
        res.status(200).send('Retorno:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/', async function (req, res) {
    try {
        const contract = contractService.getContract();
        let result = await contract.methods.probarRetorno(6).call();
        res.status(200).send('Retorno:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

// Nuestros end points

router.post('/setRol', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        await contract.methods.setRol(
            req.body.auditor,
            req.body.gestor
        ).send({
            from: accounts[0]
        });
        res.status(200).send('Retorno: Ok');
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/setActive', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        await contract.methods.setActive(
            req.body.activeStatus
        ).send({
            from: accounts[0]
        });
        res.status(200).send('Retorno: Ok');
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getOneField', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getOneField().call({
            from: accounts[0]
        });
        res.status(200).send('Address:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});


// Votacion de SubObjetivos

router.post('/addSubObjetivo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.addSubObjetivo(
            req.body.desc,
            req.body.monto,
            req.body.estado,
            req.body.ctaDestino
        ).send({
            from: accounts[0],
            gas: 300000
        });
        //.then('receipt', function(receipt) {
        //    console.log('receipt: ' + receipt)
        //})
        res.status(200).send('Ok');
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/habilitarPeriodoDeVotacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        contract.methods.habilitarPeriodoDeVotacion(
        ).send({
            from: accounts[0],
            gas: 300000
        })
        .on('error', (error) => {
            console.log('error: ' + error);
            res.status(500).send(error);
        })
        .on('receipt', (receipt) => {
            console.log('receipt: ' + receipt) // contains the new contract address
            res.status(200).send('receipt:' + receipt);
        })
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/tieneCtaActiva', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.tieneCtaActiva().call({
            from: accounts[0]
        });
        res.status(200).send('Resultado: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getVotacionActiva', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getVotacionActiva().call({
            from: accounts[0]
        });
        res.status(200).send('votacionActiva: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/setVotacionActiva', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        await contract.methods.setVotacionActiva(
            req.body.status
        ).send({
            from: accounts[0]
        });
        res.status(200).send('Retorno: Ok');
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getSubObjetivosEnProcesoDeVotacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getSubObjetivosEnProcesoDeVotacion().call({
            from: accounts[0]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getSubObjetivosPendienteEjecucion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getSubObjetivosPendienteEjecucion().call({
            from: accounts[0]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/votarSubObjetivoPendienteEjecucion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarSubObjetivoPendienteEjecucion(
            req.body.descripcion
        ).send({
            from: accounts[0]
        });
        res.status(200).send('Retorno: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/votarSubObjetivoEnProesoDeVotacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarSubObjetivoEnProesoDeVotacion(
            req.body.descripcion
        ).send({
            from: accounts[0]
        });
        res.status(200).send('Retorno: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

/*
router.post('/getAhorrista', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getAhorrista(
            req.body.ads
        ).call({
            from: accounts[0]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});
*/

router.get('/ejecutarProxSubObjetivo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.ejecutarProxSubObjetivo(
        ).send({
            from: accounts[0]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/votarCerrarPeriodoDeVotacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarCerrarPeriodoDeVotacion(
        ).send({
            from: accounts[0]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/init', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.init(
            req.body.maxAhorristas,             // uint
            req.body.ahorroObj,                 // uint
            req.body.elObjetivo,                // string
            req.body.minAporteDep,              // uint
            req.body.minAporteActivar,          // uint    
            req.body.ahorristaVeAhorroActual,   // bool
            req.body.gestorVeAhorroActual       // bool
        ).send({
            from: accounts[0],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/savingAccountState', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result1 = await contract.methods.savingAccountStatePart1(
        ).call({
            from: accounts[0]
        });
        let result2 = await contract.methods.savingAccountStatePart2(
        ).call({
            from: accounts[0]
        });
        res.status(200).send('Estados de SavingAccount: \n\n' +
            'cantMaxAhorristas: ' + result1[0] + '\n' +
            'ahorroObjetivo: ' + result1[1] + '\n' +
            'objetivo: ' + result1[2] + '\n' +
            'minAporteDeposito: ' + result1[3] + '\n' +
            'minAporteActivarCta: ' + result1[4] + '\n' +
            'ahorroActualVisiblePorAhorristas: ' + result1[5] + '\n' +
            'ahorroActualVisiblePorGestores: ' + result1[6] + '\n' +
            'cantAhorristas: ' + result1[7] + '\n' +
            'cantAhorristasActivos: ' + result2[0] + '\n' +
            'cantAhorristasAproved: ' + result2[1] + '\n' +
            'cantGestores: ' + result2[2] + '\n' +
            'cantAuditores: ' + result2[3] + '\n' +
            'administrador: ' + result2[4] + '\n' +
            'isActive: ' + result2[5] + '\n' +
            'ahorroActual: ' + result2[6] + '\n' +
            'totalRecibidoDeposito: ' + result2[7] + '\n'
        );
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/sendDepositWithRegistration', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.sendDepositWithRegistration(
            req.body.cedula,                // string
            req.body.fullName,              // string
            req.body.addressBeneficiario    // string
        ).send({
            from: accounts[0],
            gas: 300000,
            value: 300000,
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/getAhorrista', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getAhorrista(
            req.body.ads    // string
        ).call({
            from: accounts[0]
        });
        res.status(200).send('Estados del Ahorrista: \n\n' +
            'cedula: ' + result[0] + '\n' +
            'nombreCompleto: ' + result[1] + '\n' +
            'fechaIngreso: ' + result[2] + '\n' +
            'cuentaEth: ' + result[3] + '\n' +
            'cuentaBeneficenciaEth: ' + result[4] + '\n' +
            'montoAhorro: ' + result[5] + '\n' +
            'montoAdeudado: ' + result[6] + '\n' +
            'isGestor: ' + result[7][0] + '\n' +
            'isAuditor: ' + result[7][1] + '\n' +
            'isActive: ' + result[7][2] + '\n' +
            'isAproved: ' + result[7][3] + '\n' +
            'ahorristaHaVotado: ' + result[7][4] + '\n' +
            'auditorCierraVotacion: ' + result[7][5] + '\n' +
            'gestorVotaEjecucion: ' + result[7][6] + '\n'
        );
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

module.exports = router;

/*
router.post('/addSubObjetivo', async function(req, res){
    try{
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.addSubObjetivo(
            req.body.desc,
            req.body.monto,
            req.body.estado,
            req.body.ctaDestino
        ).send({
            from: accounts[0],
            gas: 300000
        }, function(error, transactionHash){
            console.log('error: ' + error, 'transactionHash: ' + transactionHash);
        })
        .on('error', function(error){
            console.log('error: ' + error);
        })
        .on('transactionHash', function(transactionHash){
            console.log('transactionHash: ' + transactionHash);
        })
        .on('receipt', function(receipt){
            console.log('receipt: ' + receipt.contractAddress) // contains the new contract address
        })
        .on('confirmation', function(confirmationNumber, receipt){
            console.log('confirmationNumber: ' + confirmationNumber + ", receipt: " + receipt);
        })
        .then(function(newContractInstance){
            console.log('newContractInstance: ' + newContractInstance.options.address) // instance with the new contract address
        });
        res.status(200).send('Ok');
    } catch(error){
        console.log(error);
        res.status(500).send(error.data);
    }
});
*/