//SPDX-License-Identifier:MIT;
pragma solidity ^0.6.1;

import './GeneralConfiguration.sol';

contract SavingAccount {
    
    // el administrador no puede ser ni gestor ni auditor
    struct Ahorrista
    {
        string cedula;
        string nombreCompleto;
        uint fechaIngreso;
        address cuentaEth;
        address cuentaBeneficenciaEth;
        uint montoAhorro;   //si isActive == false -> seria el dinero que no se suma al ahorro total del contrato
        uint montoAdeudado;
        bool isGestor;
        bool isAuditor;
        bool isActive;
        bool isAproved;
    }
    
    enum Estado {EnProcesoDeVotacion, Aprobado, Ejecutado}
    
    struct SubObjetivo {
        string descripcion;
        uint monto;
        Estado estado;
    }
    
    uint cantAhorristas;        //incluye todos 
    uint cantAhorristasActivos; //incluye activos (sin importar si estan aprobados o no)
    uint cantAhorristasAproved; //solo los ahorristas isAproved == true
    uint cantGestores;
    uint cantAuditores;
    mapping(address => Ahorrista) public ahorristas;
    mapping(uint => address) public ahorristasIndex;
    SubObjetivo[] public subObjetivos;
    
    GeneralConfiguration public generalConf;
    address payable public administrador;
    bool public isActive;  //para activarlo minimo (Ahorristas >= 6 && Gestores 1 cada 3 Ahorristas && Auditor 1 cada 2 Gestores), pero pueden ser otras cantidades
                           //establecidas en el contrato de configuracion, un ahorrista no puede ser Gestor y Auditor a la vez
    uint cantMaxAhorristas; // >= 6
    uint ahorroActual; //capaz es el balance!!!!
    uint ahorroObjetivo;
    string objetivo;
    uint minAporteDeposito; // >= 0
    uint minAporteActivarCta;
    bool ahorroActualVisiblePorAhorristas;
    bool ahorroActualVisiblePorGestores;
    
    uint totalRecibidoDeposito;  //no me queda claro para que sirve
    
    
    
    modifier onlyAdmin() {
        require(msg.sender == administrador, 'Not the Admin');
        _;
    }
    
    modifier onlyAuditor() {
        require(ahorristas[msg.sender].isAuditor == true, 'Not an Auditor');
        _;
    }
    
    modifier onlyAdminOrAuditor() {
        require(msg.sender == administrador || ahorristas[msg.sender].isAuditor == true, 'Not an Admin or an Auditor');
        _;
    }
    
    modifier onlyGestor() {
        require(ahorristas[msg.sender].isGestor == true, 'Not an Gestor');
        _;
    }
    
    modifier receiveMinDepositAmount() {
        require(msg.value >= minAporteDeposito, 'Not enough deposit amount');
        _;
    }
    
    modifier savingContractIsActive() {
        require(isActive == true, 'Saving Acccount Contract not active');
        _;
    }
    
    // constructor() public
    // {   
    //     administrador = msg.sender;
    //     isActive = false;
    // }

    // function init(uint maxAhorristas, uint ahorroObj, string memory elObjetivo, uint minAporteDep, uint minAporteActivar, bool ahorristaVeAhorroActual, bool gestorVeAhorroActual) public
    // {
    //     require(maxAhorristas >= 6, "maxAhorristas must be greater than 5");
    //     require(minAporteDep >= 0, "minAporteDep must be a positive value"); //ver si sirve
    //     require(bytes(elObjetivo).length != 0, "elObjetivo must be specified");
        
    //     // administrador = msg.sender;
    //     // isActive = false;
    //     cantMaxAhorristas = maxAhorristas;
    //     ahorroObjetivo = ahorroObj;
    //     objetivo = elObjetivo;
    //     minAporteDeposito = minAporteDep;
    //     minAporteActivarCta = minAporteActivar;
    //     ahorroActualVisiblePorAhorristas = ahorristaVeAhorroActual;
    //     ahorroActualVisiblePorGestores = gestorVeAhorroActual;
    // }
    
    //mock para pruebas
    constructor() public
    {   
        administrador = msg.sender;
        isActive = true;
        cantMaxAhorristas = 15;
        ahorroObjetivo = 10000;
        objetivo = "comprar una casa";
        minAporteDeposito = 10;
        minAporteActivarCta = 20;
        ahorroActualVisiblePorAhorristas = true;
        ahorroActualVisiblePorGestores = true;
    }
    
    function setConfigAddress( GeneralConfiguration _address ) public {
        generalConf = _address;
    }
    
    function getAhorroActual() public onlyAdminOrAuditor view returns (uint) {
        return ahorroActual;
    }
    
    function addSubObjetivo(string memory desc, uint monto, Estado estado) public onlyAdmin {
        subObjetivos.push(SubObjetivo(desc,monto,estado));
    }
    
    //item 10 
    function sendDepositWithRegistration(string memory cedula, string memory fullName, address addressBeneficiario) public payable savingContractIsActive receiveMinDepositAmount {
        uint elTime = block.timestamp;
        uint monto = msg.value;
        address addAux = msg.sender;
        address addAux2 = addressBeneficiario;
        
        /*
        string cedula;
        string nombreCompleto;
        uint fechaIngreso;
        address cuentaEth;
        address cuentaBeneficenciaEth;
        uint montoAhorro;   //si isActive == false -> seria el dinero que no se suma al ahorro total del contrato
        uint montoAdeudado;
        bool isGestor;
        bool isAuditor;
        bool isActive;
        bool isAproved;
        */
        
        if (!isInMapping(msg.sender))
        {
            //ahorristas[msg.sender] = Ahorrista(cedula, fullName, block.timestamp, msg.sender, addressBeneficiario, msg.value, 0, false, false, false, false);
            //Ahorrista memory ahoAux = Ahorrista(cedula, fullName, elTime, addAux, addAux2, monto, 0, false, false, false, false);
            ahorristas[addAux].cedula = cedula;
            ahorristas[addAux].nombreCompleto = fullName;
            ahorristas[addAux].fechaIngreso = elTime;
            ahorristas[addAux].cuentaEth = addAux;
            ahorristas[addAux].cuentaBeneficenciaEth = addAux2;
            ahorristas[addAux].montoAhorro = monto;
            ahorristas[addAux].montoAdeudado = 0;
            ahorristas[addAux].isGestor = false;
            ahorristas[addAux].isAuditor = false;
            ahorristas[addAux].isActive = false;
            ahorristas[addAux].isAproved = false;
            
            ahorristasIndex[cantAhorristas] = msg.sender;
            cantAhorristas++;
            if(msg.value >= minAporteActivarCta){
                ahorristas[msg.sender].isActive = true;
                cantAhorristasActivos++;
            }
        }
    }
    
    function sendDeposit() public payable savingContractIsActive receiveMinDepositAmount {
        if (isInMapping(msg.sender))
        {
            ahorristas[msg.sender].montoAhorro += msg.value;
            if (ahorristas[msg.sender].isAproved) {
                ahorroActual += msg.value;
            }else if(!ahorristas[msg.sender].isActive && ahorristas[msg.sender].montoAhorro >= minAporteActivarCta){
                ahorristas[msg.sender].isActive = true;
                cantAhorristasActivos++;
            }
        }
    }
    
    function isInMapping(address unAddress) private view returns(bool)
    {
        return ahorristas[unAddress].cuentaEth != address(0);
    }
    
    function aproveAhorrista(address unAddress) public onlyAuditor returns (bool) {
        bool retorno = false;
        
        if (isInMapping(unAddress) && ahorristas[unAddress].isActive == true) 
        {
            if (isActive == false) 
            {
                ahorristas[unAddress].isAproved = true;
                cantAhorristasAproved++;
                ahorroActual += ahorristas[unAddress].montoAhorro;
                retorno = true; 
            }
            else if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, cantAuditores)) 
            {
                ahorristas[unAddress].isAproved = true;
                cantAhorristasAproved++;
                ahorroActual += ahorristas[unAddress].montoAhorro;
                retorno = true;
            }  
        }
        return retorno;
    }
    
    function getAhorristasToAprove() public onlyAuditor view returns(address[] memory) {
        address[] memory losActivosSinAprobar = new address[](cantAhorristasActivos - cantAhorristasAproved);
        uint j = 0;
        if (cantAhorristasActivos - cantAhorristasAproved > 0) 
        {
            for(uint i=0; i<cantAhorristas; i++) {
                if(ahorristas[ahorristasIndex[i]].isActive && !ahorristas[ahorristasIndex[i]].isAproved)
                    {
                        losActivosSinAprobar[j] = ahorristas[ahorristasIndex[i]].cuentaEth;    
                        j++;
                    }
            }
        }
        return losActivosSinAprobar;
    }
    
    
    //////////////////////////////////////////
    ////////// METODOS DE PRUEBA /////////////
    //////////////////////////////////////////
    
    
    function setRol(bool auditor, bool gestor) public {
        ahorristas[msg.sender].isAuditor = auditor;
        ahorristas[msg.sender].isGestor = gestor;
    }
    
    function getOneField() public view returns (address){
        return ahorristas[msg.sender].cuentaEth;
    }
    
    // function retornaBoolean(uint valor) public pure returns(bool) {
    //     require(valor < 5, 'menor a 5 no funca');
    //     if(valor<10){
    //         return true;
    //     }else{
    //         return false;
    //     }
    // } 
    
    // function probarRetorno(uint valor) public pure returns(bool){
    //     bool retorno = retornaBoolean(valor);
        
    //     return retorno;
    // }
    
    // function getAhorristasToAprove() public onlyAuditor view returns (string[] memory){ 
    //     string[] memory losActivosSinAprobar = new string[](cantAhorristasActivos - cantAhorristasAproved);
    //     uint j = 0;
    //     if (cantAhorristasActivos - cantAhorristasAproved > 0) 
    //     {
    //         for(uint i = 0; i < cantAhorristas; i++)
    //         {
    //             if(ahorristas[ahorristasIndex[i]].isActive && !ahorristas[ahorristasIndex[i]].isAproved)
    //             {
    //                 losActivosSinAprobar[j] = (abi.encodePacked(ahorristas[ahorristasIndex[i]].cuentaEth));    
    //                 j++;
    //             }
    //         }    
    //     }
        
    //     return losActivosSinAprobar;
    // }
    
     /*
    function getMappingValue() public view returns (uint[] memory) {
        uint[] memory memoryArray = new uint[](myVariable.sizeOfMapping);
        for(uint i = 0; i < myVariable.sizeOfMapping; i++) {
            memoryArray[i] = myVariable.myMappingInStruct[i];
        }
        return memoryArray;
    }
    
    function name() public view returns(address[] memory) {
        address[] memory playerList;
        for(uint i=0; i<getPlayerCount(); i++) {
            playerList[i] = players[i];
        }
        return playerList;
    }
    */
    
}