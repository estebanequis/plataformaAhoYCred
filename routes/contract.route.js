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

//////////////////////////////////////////
///////////// Items 1 al 5 ///////////////
///////////////// Base ///////////////////
//////////////////////////////////////////

router.post('/setConfigAddress', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.setConfigAddress(
            req.body.configAddress    // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/activarSavingAccount', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        await contract.methods.activarSavingAccount()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send('Retorno: Ok');
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
///////////// Items 6 al 10 //////////////
/////// Init, Registro y Deposito ////////
//////////////////////////////////////////

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
            req.body.gestorVeAhorroActual,      // bool
            req.body.recargo,                   // uint
            req.body.pMaxPrestamo,              // uint
            req.body.pDtoAporteAudGest,         // uint
            req.body.pAlAbandonar,              // uint
            req.body.pzoRevocarFallecimiento    // uint
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
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
            from: accounts[req.query.cta],
            gas: 3000000,
            value: req.body.amount
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/sendDeposit', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.sendDeposit()
        .send({
            from: accounts[req.query.cta],
            gas: 300000,
            value: req.body.amount
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/aproveAhorrista', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.aproveAhorrista(
            req.body.addressAhorrista    // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getAhorristasToAprove', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getAhorristasToAprove()
        .call({
            from: accounts[req.query.cta]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
////////// Items 11 al 17 ////////////////
/////// Votacion de Subobjetivos /////////
//////////////////////////////////////////

router.post('/addSubObjetivo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        console.log(req.body.monto);
        let result = await contract.methods.addSubObjetivo(
            req.body.desc,
            req.body.monto,
            req.body.ctaDestino
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
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
        contract.methods.habilitarPeriodoDeVotacion()
        .send({
            from: accounts[req.query.cta],
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

router.get('/getSubObjetivosEnProcesoDeVotacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getSubObjetivosEnProcesoDeVotacion()
        .call({
            from: accounts[req.query.cta]
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
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
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send('Retorno: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/votarCerrarPeriodoDeVotacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarCerrarPeriodoDeVotacion()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
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
        let result = await contract.methods.getSubObjetivosPendienteEjecucion()
        .call({
            from: accounts[req.query.cta]
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
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Retorno: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/ejecutarProxSubObjetivo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.ejecutarProxSubObjetivo()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/getPublishedEventByGestor', async function (req, res) {
    try {
        const contract = contractService.getContract();
        let eventMethodName = 'SubObjetivoEvent(address,string,string,uint,address)';
        let filterEventMethod = web3.utils.sha3(eventMethodName);
        let filters = {
            address: contract._address,
            fromBlock: "0x1",
            toBlock: "latest",
            topics: [filterEventMethod, web3.utils.sha3(req.body.gestorAddress), null]
        }
        let result = await web3.eth.getPastLogs(filters);
        res.status(200).send('SubObjetivoEvent message: ' + web3.eth.util.hexToUtf8(result[0].data));
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/getPublishedEventByObjetivo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        let eventMethodName = 'SubObjetivoEvent(address,string,string,uint,address)';
        let filterEventMethod = web3.utils.sha3(eventMethodName);
        let filters = {
            address: contract._address,
            fromBlock: "0x1",
            toBlock: "latest",
            topics: [filterEventMethod, null, web3.utils.sha3(req.body.objetivo)]
        }
        let result = await web3.eth.getPastLogs(filters);
        res.status(200).send('SubObjetivoEvent message: ' + web3.eth.util.hexToUtf8(result[0].data));
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
///////////// Items 19 al 21 /////////////
/////////// Votacion de Roles ////////////
//////////////////////////////////////////

router.get('/habilitarPostulacionDeCandidatos', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.habilitarPostulacionDeCandidatos()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/postularseComoGestor', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.postularseComoGestor()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/postularseComoAuditor', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.postularseComoAuditor()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/habilitarVotoDeCandidatos', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.habilitarVotoDeCandidatos()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/votarGestor', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarGestor(
            req.body.gestorAdrs    // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/votarAuditor', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarAuditor(
            req.body.auditorAdrs    // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/cerrarVotoDeCandidatos', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.cerrarVotoDeCandidatos()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
///////////// Items 22 al 23 /////////////
//////////// Monto de ahorro /////////////
//////////////////////////////////////////

router.get('/getAhorroActual', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getAhorroActual()
        .call({
            from: accounts[req.query.cta]
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/solicitarVerMontoAhorro', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.solicitarVerMontoAhorro()
        .send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/permitirVerMontoAhorro', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.permitirVerMontoAhorro(
            req.body.ahorristaAdrs    // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/revocarVerMontoAhorro', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.revocarVerMontoAhorro(
            req.body.ahorristaAdrs    // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        console.log(result);
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
///////////// Items 24 al 26 /////////////
//////////////// Prestamos ///////////////
//////////////////////////////////////////

router.post('/solicitarPrestamo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.solicitarPrestamo(
            req.body.montoSolicitado    // uint
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/adjudicarPrestamo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.adjudicarPrestamo(
            req.body.ahorristaAdrs      // string
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/pagarPrestamo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.pagarPrestamo()
        .send({
            from: accounts[req.query.cta],
            gas: 300000,
            value: req.body.montoPago
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
//////////////// Item 27 /////////////////
/////////// Plazo de deposito ////////////
//////////////////////////////////////////

router.post('/pagarRecargo', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.pagarRecargo()
        .send({
            from: accounts[req.query.cta],
            gas: 300000,
            value: req.body.montoRecargo
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
///////////// Items 28 al 29 /////////////
//////////////// Abandonar ///////////////
//////////////////////////////////////////

router.post('/abandonarContrato', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.abandonarContrato(
            req.body.conRetiro      // bool
        ).send({
            from: accounts[req.query.cta],
            gas: 300000
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
/////////// Items 30, 31 y 33 ////////////
///////////// Fallecimiento //////////////
//////////////////////////////////////////

router.post('/votarFallecimiento', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarFallecimiento(
            req.body.adrs       // string
        ).send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/revocarFallecimiento', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.revocarFallecimiento()
        .send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/liquidarCuentaAhorro', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.liquidarCuentaAhorro(
            req.body.adrs       // string
        ).send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
///////////// Items 34 y 35 //////////////
/////////// Liquidar Contrato ////////////
//////////////////////////////////////////

router.get('/liquidarContrato', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.liquidarContrato()
        .send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/votarLiquidarContrato', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.votarLiquidarContrato()
        .send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

//////////////////////////////////////////
//////// GeneralConfiguration ////////////
//////////////////////////////////////////

router.post('/setPctComisionLiquidacion', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.setPctComisionLiquidacion(
            req.body.pComisionLiquidacion       // string
        ).send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/setDolaresComisionApertura', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.setDolaresComisionApertura(
            req.body.dlsComisionApertura       // string
        ).send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.post('/setCotizacionDolar', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.setCotizacionDolar(
            req.body.cotDolar       // string
        ).send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Resultado:' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});


//////////////////////////////////////////
////////// METODOS DE PRUEBA /////////////
//////////////////////////////////////////

router.get('/setGestorTrue', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        await contract.methods.setGestorTrue().send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Retorno: Ok');
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/setAuditorTrue', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        await contract.methods.setAuditorTrue().send({
            from: accounts[req.query.cta],
            gas: 3000000
        });
        res.status(200).send('Retorno: Ok');
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
            from: accounts[req.query.cta]
        });
        res.status(200).send('votacionActiva: ' + result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getAhorristas', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getAhorristas().call({
            from: accounts[req.query.cta]
        });
        var retorno = "Estados de los Ahorristas: \n\n";
        for(var i=0; i<result.length; i++){
            retorno += 'cedula: ' + result[i][0] + '\n' +
            'nombreCompleto: ' + result[i][1] + '\n' +
            'fechaIngreso: ' + result[i][2] + '\n' +
            'cuentaEth: ' + result[i][3] + '\n' +
            'cuentaBeneficenciaEth: ' + result[i][4] + '\n' +
            'montoAhorro: ' + result[i][5] + '\n' +
            'Prestamos: \n' +
            '   solicitoPrestamo: ' + result[i][6][0] + '\n' +
            '   montoSolicitado: ' + result[i][6][1] + '\n' +
            '   montoAdeudado: ' + result[i][6][2] + '\n' +
            'Banderas: \n' +
            '   EstadoAhorrista: \n' +
            '       isGestor: ' + result[i][7][0][0] + '\n' +
            '       isAuditor: ' + result[i][7][0][1] + '\n' +
            '       isActive: ' + result[i][7][0][2] + '\n' +
            '       isAproved: ' + result[i][7][0][3] + '\n' +
            '       isAlive: ' + result[i][7][0][4] + '\n' +
            '   VotoSubObjetivos: \n' +
            '       ahorristaVotaSubObjetivo: ' + result[i][7][1][0] + '\n' +
            '       auditorCierraVotacion: ' + result[i][7][1][1] + '\n' +
            '       gestorVotaEjecucion: ' + result[i][7][1][2] + '\n' +
            '   VotoRoles: \n' +
            '       votoAGestor: ' + result[i][7][2][0] + '\n' +
            '       votoAAuditor: ' + result[i][7][2][1] + '\n' +
            '       postuladoComoGestor: ' + result[i][7][2][2] + '\n' +
            '       postuladoComoAuditor: ' + result[i][7][2][3] + '\n' +
            '       votosRecibidoComoGestor: ' + result[i][7][2][4] + '\n' +
            '       votosRecibidoComoAuditor: ' + result[i][7][2][5] + '\n' +
            '   VisualizarAhorro: \n' +
            '       solicitoVerAhorro: ' + result[i][7][3][0] + '\n' +
            '       tienePermiso: ' + result[i][7][3][1] + '\n' +
            '   Fallecimiento: \n' +
            '       isAlive: ' + result[i][7][4][0] + '\n' +
            '       yaVoto: ' + result[i][7][4][1] + '\n' +
            '       cantVotos: ' + result[i][7][4][2] + '\n' +
            '       fechaFallecimiento: ' + result[i][7][4][3] + '\n' +
            '   ultimoDeposito: ' + result[i][7][5] + '\n' +
            '   liquidarContrato: ' + result[i][7][6] + '\n\n';
        }
        res.status(200).send(retorno);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/savingAccountState', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result1 = await contract.methods.savingAccountStatePart1()
        .call({
            from: accounts[req.query.cta]
        });
        let result2 = await contract.methods.savingAccountStatePart2()
        .call({
            from: accounts[req.query.cta]
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

router.get('/getSubObjetivos', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getSubObjetivos().call({
            from: accounts[req.query.cta]
        });
        var retorno = "Estados de los SubObjetivos: \n\n";
        for(var i=0; i<result.length; i++){
            var estado = '';
            switch (result[i][2]) {
                case '0':
                    estado = 'EnProcesoDeVotacion';
                    break;
                case '1':
                    estado = 'Aprobado';
                    break;
                case '2':
                    estado = 'PendienteEjecucion';
                    break;
                case '3':
                    estado = 'Ejecutado';
                    break;
            }
            retorno += 'descripcion: ' + result[i][0] + '\n' +
            'monto: ' + result[i][1] + '\n' +
            'estado: ' + estado + '\n' +
            'ctaDestino: ' + result[i][3] + '\n' +
            'cantVotos: ' + result[i][4] + '\n\n';
        }
        res.status(200).send(retorno);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getRealBalance', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getRealBalance()
        .call({
            from: accounts[req.query.cta]
        });
        res.status(200).send(result);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

router.get('/getVotacionRolesState', async function (req, res) {
    try {
        const contract = contractService.getContract();
        const accounts = await web3.eth.getAccounts();
        let result = await contract.methods.getVotacionRolesState()
        .call({
            from: accounts[req.query.cta]
        });
        var retorno = "Estado de la Votacion de Roles: ";
            var estado = '';
            switch (result) {
                case '0':
                    estado = 'Cerrado';
                    break;
                case '1':
                    estado = 'Postulacion';
                    break;
                case '2':
                    estado = 'Votacion';
                    break;
            }
            retorno += estado + "\n\n";
        res.status(200).send(retorno);
    } catch (error) {
        console.log(error);
        res.status(500).send(error.data);
    }
});

module.exports = router;
