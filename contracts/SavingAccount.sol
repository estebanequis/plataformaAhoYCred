//SPDX-License-Identifier:MIT;
pragma solidity ^0.6.1;

pragma experimental ABIEncoderV2;
import './GeneralConfiguration.sol';

contract SavingAccount {
    
    // el administrador no puede ser ni gestor ni auditor
    struct Ahorrista {
        string cedula;
        string nombreCompleto;
        uint fechaIngreso;
        address cuentaEth;
        address cuentaBeneficenciaEth;
        uint montoAhorro;   //si isActive == false -> seria el dinero que no se suma al ahorro total del contrato
        uint montoAdeudado;
        Banderas banderas;
    }
    
    struct Banderas {
        bool isGestor;
        bool isAuditor;
        bool isActive;
        bool isAproved;
        bool ahorristaVotaSubObjetivo;
        bool auditorCierraVotacion;
        bool gestorVotaEjecucion;
        VotoRoles votoRoles;
    }

    struct VotoRoles {
        bool votoAGestor;
        bool votoAAuditor;
        bool postuladoComoGestor;
        bool postuladoComoAuditor;
        uint votosRecibidoComoGestor;
        uint votosRecibidoComoAuditor;
    }

    enum EstadoVotacionRoles {Cerrado, Postulacion, Votacion}
    EstadoVotacionRoles estadoVotacionRoles;
    
    enum Estado {EnProcesoDeVotacion, Aprobado, PendienteEjecucion, Ejecutado}
    
    struct SubObjetivo {
        string descripcion;
        uint monto;
        Estado estado;
        address payable ctaDestino;
        uint cantVotos;
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
    bool votacionActiva;   //bandera para indicar periodo de votacion activo
    uint totalRecibidoDeposito;  //no me queda claro para que sirve
    
    // Probar
    // Item 17
    event SubObjetivoEvent(address indexed gestorAdrs, string indexed descripcion, uint monto, address ctaDestino);
    function ejecutarSubObjetivoEvent(uint subObjIndex, address gestorAdrs) public {
        emit SubObjetivoEvent(
            gestorAdrs,
            subObjetivos[subObjIndex].descripcion,
            subObjetivos[subObjIndex].monto,
            subObjetivos[subObjIndex].ctaDestino
        );
    }

    modifier onlyAdmin() {
        require(msg.sender == administrador, 'Not the Admin');
        _;
    }
    
    modifier onlyAhorristas() {
        require(isInAhorristasMapping(msg.sender) == true, 'Not an Ahorrista');
        _;
    }
    
    modifier onlyAuditor() {
        require(ahorristas[msg.sender].banderas.isAuditor == true, 'Not an Auditor');
        _;
    }
    
    modifier onlyAdminOrAuditor() {
        require(msg.sender == administrador || ahorristas[msg.sender].banderas.isAuditor == true, 'Not an Admin or an Auditor');
        _;
    }
    
    modifier onlyGestor() {
        require(ahorristas[msg.sender].banderas.isGestor == true, 'Not an Gestor');
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
    
    constructor() public {   
        administrador = msg.sender;
        //isActive = true; // Solo para test, debe ser false
        votacionActiva = false;
    }

    function setConfigAddress( GeneralConfiguration _address ) public {
        generalConf = _address;
    }
    
    // item 22
    function getAhorroActual() public onlyAdminOrAuditor view returns (uint) {
        return ahorroActual;
    }

    // item 3
    function activarSavingAccount() public onlyAdmin {
        if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, cantAuditores)){
            isActive = true;
        }  
    }

    //////////////////////////////////////////
    ///////////// Items 6 al 10 //////////////
    /////// Init, Registro y Deposito ////////
    //////////////////////////////////////////

    // Endpoint
    // Item 7 y 9
    function init(uint maxAhorristas, uint ahorroObj, string memory elObjetivo, uint minAporteDep, uint minAporteActivar, bool ahorristaVeAhorroActual, bool gestorVeAhorroActual) public onlyAdmin {
        require(maxAhorristas >= 6, "maxAhorristas must be greater than 5");
        require(minAporteDep >= 0, "minAporteDep must be a positive value"); //ver si sirve
        require(bytes(elObjetivo).length != 0, "elObjetivo must be specified");

        cantMaxAhorristas = maxAhorristas;
        ahorroObjetivo = ahorroObj;
        objetivo = elObjetivo;
        minAporteDeposito = minAporteDep;
        minAporteActivarCta = minAporteActivar;
        ahorroActualVisiblePorAhorristas = ahorristaVeAhorroActual;
        ahorroActualVisiblePorGestores = gestorVeAhorroActual;
        estadoVotacionRoles = EstadoVotacionRoles.Cerrado;
    }

    // Endpoint
    // Item 8 y 10
    function sendDepositWithRegistration(string memory cedula, string memory fullName, address addressBeneficiario) public payable receiveMinDepositAmount {
        address addressUser = msg.sender;
        if (!isInAhorristasMapping(addressUser)) {
            ahorristas[addressUser].cedula = cedula;
            ahorristas[addressUser].nombreCompleto = fullName;
            ahorristas[addressUser].fechaIngreso = block.timestamp;
            ahorristas[addressUser].cuentaEth = addressUser;
            ahorristas[addressUser].cuentaBeneficenciaEth = addressBeneficiario;
            ahorristas[addressUser].montoAhorro = msg.value;
            ahorristas[addressUser].montoAdeudado = 0;
            ahorristas[addressUser].banderas = Banderas(false,false,false,false,false,false, false, VotoRoles(false, false, false, false, 0, 0));
            ahorristasIndex[cantAhorristas] = addressUser;
            cantAhorristas++;
            if(msg.value >= minAporteActivarCta){
                ahorristas[addressUser].banderas.isActive = true;
                cantAhorristasActivos++;
            }
        }
    }
    
    //Endpoint
    // Item 6, 8 
    function sendDeposit() public payable savingContractIsActive receiveMinDepositAmount {
        if (isInAhorristasMapping(msg.sender))
        {
            ahorristas[msg.sender].montoAhorro += msg.value;
            if (ahorristas[msg.sender].banderas.isAproved) {
                ahorroActual += msg.value;
            }else if(!ahorristas[msg.sender].banderas.isActive && ahorristas[msg.sender].montoAhorro >= minAporteActivarCta){
                ahorristas[msg.sender].banderas.isActive = true;
                cantAhorristasActivos++;
            }
        }
    }
    
    //Endpoint
    // Item 10
    function aproveAhorrista(address unAddress) public onlyAuditor returns (bool) {
        bool retorno = false;
        if (isInAhorristasMapping(unAddress) && ahorristas[unAddress].banderas.isActive == true) 
        {
            if (isActive == false) 
            {
                ahorristas[unAddress].banderas.isAproved = true;
                cantAhorristasAproved++;
                ahorroActual += ahorristas[unAddress].montoAhorro;
                retorno = true; 
            }
            else if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, cantAuditores)) 
            {
                ahorristas[unAddress].banderas.isAproved = true;
                cantAhorristasAproved++;
                ahorroActual += ahorristas[unAddress].montoAhorro;
                retorno = true;
            }  
        }
        return retorno;
    }
    
    // Endpoint
    // Item 10
    function getAhorristasToAprove() public onlyAuditor view returns(address[] memory) {
        address[] memory losActivosSinAprobar = new address[](cantAhorristasActivos - cantAhorristasAproved);
        uint j = 0;
        if (cantAhorristasActivos - cantAhorristasAproved > 0) 
        {
            for(uint i=0; i<cantAhorristas; i++) {
                if(ahorristas[ahorristasIndex[i]].banderas.isActive && !ahorristas[ahorristasIndex[i]].banderas.isAproved)
                    {
                        losActivosSinAprobar[j] = ahorristas[ahorristasIndex[i]].cuentaEth;    
                        j++;
                    }
            }
        }
        return losActivosSinAprobar;
    }
    
    //////////////////////////////////////////
    ////////// Items 11 al 16 ////////////////
    /////// Votacion de Subobjetivos /////////
    //////////////////////////////////////////
    
    // Endpoint
    /* El Admin puede agregar un SubObjetivo */
    function addSubObjetivo(string memory desc, uint monto, address payable ctaDestino) public onlyAdmin {
        Estado estado = Estado(0);
        subObjetivos.push(SubObjetivo(desc, monto, estado, ctaDestino, 0));
    }

    // Endpoint
    /* En caso de que exista al menos 1 SubObjetivo con estado EnProcesoDeVotacion
    Se habilitara el periodo de votacion */
    function habilitarPeriodoDeVotacion() public onlyAdmin returns(bool) {
        // Se resetean las banderas
        for(uint i=0; i<cantAhorristas; i++) {
            ahorristas[ahorristasIndex[i]].banderas.ahorristaVotaSubObjetivo = false;
            ahorristas[ahorristasIndex[i]].banderas.auditorCierraVotacion = false;
        }
        // Se fija si existe al menos un SubObjetivo con estado EnProcesoDeVotacion En caso de encontrarlo, activa la votacion
        for(uint i=0; i<subObjetivos.length; i++) {
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion) {
                votacionActiva = true;
                return true;
            }
        }
        return false;
    }

    // Endpoint
    /* Los ahorristas pueden obtener un listado de los SubObjetivos disponibles */
    function getSubObjetivosEnProcesoDeVotacion() public onlyAhorristas view returns(string[] memory) {
        require(votacionActiva == true, 'Para obtener la lista de SubObjetivos, es necesario que la votacion se encuentre activa.');
        require(tieneCtaActiva(msg.sender) == true, 'Para obtener la lista de SubObjetivos, es necesario que su cuenta este activa.');
        // Se obtiene la cantidad de SubObjetivos que se encuentran EnProcesoDeVotacion
        uint cantSubObj=0;
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion){
                cantSubObj++;     
            }
        }
        string[] memory losSubObjetivos = new string[](cantSubObj);
        // Se agrega a la lista a retornar, las descripciones de cada uno de los SubObjetivos en proceso de votacion
        uint j = 0;
        for(uint i=0; i<subObjetivos.length; i++) {
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion) {
                losSubObjetivos[j] = subObjetivos[i].descripcion;
                j++;
            }
        }
        return losSubObjetivos;
    }

    // Endpoint
    /* Todos los ahorristas con cuentas activas pueden votar durante el periodo de votacion una unica vez */
    function votarSubObjetivoEnProesoDeVotacion(string memory descripcion) public onlyAhorristas returns(string memory) {
        require(votacionActiva == true, 'No existe periodo de votacion abierto.');
        require(tieneCtaActiva(msg.sender) == true, 'Su cuenta no esta activa, no puede votar.');
        require(ahorristas[msg.sender].banderas.ahorristaVotaSubObjetivo == false, 'Ya ha votado.');
        // Buscamos los SubObjetivos con estado EnProcesoDeVotacion.
        // Si existe alguno con la misma descripcion ingresada, se le agrega un voto
        // Y se marca al ahorrista como que ha votado.
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion){
                if(keccak256(abi.encodePacked(subObjetivos[i].descripcion)) == keccak256(abi.encodePacked(descripcion))){
                    subObjetivos[i].cantVotos++;
                    ahorristas[msg.sender].banderas.ahorristaVotaSubObjetivo = true;
                    return "OK";
                }         
            }
        }
        return "No se encontro el subobjetivo";
    }

    // Endpoint
    /* Los auditores pueden votar para cerrar el periodo de votacion */
    function votarCerrarPeriodoDeVotacion() public onlyAuditor returns(string memory) {
        if(votacionActiva == false) { return "No existe periodo de votacion abierto"; }
        // Se agrega el voto al auditor que llamo al metodo
        ahorristas[msg.sender].banderas.auditorCierraVotacion = true;
        // Buscamos si existe algun auditor sin votar
        for(uint i=0; i<cantAhorristas; i++) {
            if (ahorristas[ahorristasIndex[i]].banderas.auditorCierraVotacion == false && ahorristas[ahorristasIndex[i]].banderas.isAuditor == true) {
                return "Se ha agregado su voto pero faltan Auditores por votar";
            }
        }
        // Como todos los auditores votaron cerrar el periodo, se cierra la votacion
        votacionActiva = false;
        // Todos los SubObjetivos que tuvieron votos, se pasan a estado Aprobado
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion && subObjetivos[i].cantVotos > 0){
               subObjetivos[i].estado = Estado.Aprobado;
            }
        }
        return "El periodo de votacion ha quedado cerrado";
    }

    // Endpoint
    /* Los gestores pueden obtener un listado de los SubObjetivos pendientes de ejecucion */
    function getSubObjetivosPendienteEjecucion() public onlyGestor view returns(string[] memory) { 
        // Se obtiene la cantidad de SubObjetivos que se encuentran pendientes de ejecucion
        uint cantSubObj=0;
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.PendienteEjecucion){
                cantSubObj++;     
            }
        }
        string[] memory losSubObjetivos = new string[](cantSubObj);
        // Se agrega a la lista de retorno los SubObjetivos pendientes de ejecucion
        uint j = 0;
        for(uint i=0; i<subObjetivos.length; i++) {
            if(subObjetivos[i].estado == Estado.PendienteEjecucion) {
                losSubObjetivos[j] = subObjetivos[i].descripcion;    
                j++;
            }
        }
        return losSubObjetivos;
    }

    // Endpoint
    /* Los gestores pueden votar un SubObjetivo */
    function votarSubObjetivoPendienteEjecucion(string memory descripcion) public onlyGestor returns(string memory){ 
        require(ahorristas[msg.sender].banderas.gestorVotaEjecucion == false, 'Ya has votado.');
        // Se busca en la lista de SubObjetivos los SubObjetivos pendientes de ejecucion
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.PendienteEjecucion){
                // Si se encuentra uno con la misma descripcion del request, se le agrega el voto al Gestor
                if(keccak256(abi.encodePacked(subObjetivos[i].descripcion)) == keccak256(abi.encodePacked(descripcion))){
                    ahorristas[msg.sender].banderas.gestorVotaEjecucion = true;
                    uint cantGestoresAprobaron = 0;
                    // Se busca la cantidad de Gestores que han votado la ejecucion hasta el momento
                    for(uint j=0; j<cantAhorristas; j++) {
                        if (ahorristas[ahorristasIndex[j]].banderas.isGestor == true && ahorristas[ahorristasIndex[j]].banderas.gestorVotaEjecucion == true){
                            cantGestoresAprobaron++;
                        }
                    }
                    // Si ya existia otro Gestor que voto la ejecucion, entonces se ejecuta el SubObjetivo
                    if(cantGestoresAprobaron >= 2) {
                        ejecutarSubObjetivo(i);
                        // Se resetean las banderas de votos de los gestores
                        for(uint k=0; k<cantAhorristas; k++) {
                            ahorristas[ahorristasIndex[k]].banderas.gestorVotaEjecucion = false;
                        }
                        return string(abi.encodePacked("Se ejecuto el SubObjetivo ", subObjetivos[i].descripcion));
                    }
                    return "Se ha agregado su voto pero todavia falta un Gestor por votar";
                }         
            }
        }
        return "No se encontro el subobjetivo";
    }

    // TODO: Verificar por que no se transfiere realmente los weis
    /* Ejecuta un SubObjetivo segun su index en la lista de SubObjetivos */
    function ejecutarSubObjetivo(uint index) private {
        subObjetivos[index].estado = Estado.Ejecutado;
        ahorroActual = ahorroActual - subObjetivos[index].monto;
        subObjetivos[index].ctaDestino.transfer(subObjetivos[index].monto);
        ejecutarSubObjetivoEvent(index, msg.sender);
    }
    
    // Endpoint
    function ejecutarProxSubObjetivo() public onlyGestor returns (string memory) {
        uint maxVotos = 0;
        uint subObjIndex = 0;
        bool existePendiente = false;
        // Se busca en la lista de SubObjetivos el indice y la cantidad de votos del mas votado
        // Si tenia como estado Pendiente de ejecucion, se pone existePendiente
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.Aprobado){
               if(subObjetivos[i].cantVotos > maxVotos) {
                   maxVotos = subObjetivos[i].cantVotos;
                   subObjIndex = i;
               }
            }
            if(subObjetivos[i].estado == Estado.PendienteEjecucion){
                existePendiente = true;
            }
        }
        // Si tiene plata el SubObjetivo mas votado y el monto es menor o igual al ahorro actual, se ejecuta
        if(maxVotos > 0 && subObjetivos[subObjIndex].monto <= ahorroActual) {
            ejecutarSubObjetivo(subObjIndex);
            return subObjetivos[subObjIndex].descripcion;
        }
        // Si ya existia un SubObjetivo pendiente de ejecucion, entonces no se permite que exista otro mas pendiente de ejecucion
        if(existePendiente == true) { return "Ya existe un SubObjetivo pendiente de ejecucion"; }
        // En caso de que no exista un SubObjetivo pendiente de ejecucion, entonces se procede a encontrar
        // Al proximo mas votado, pero que se tenga el ahorro suficiente para poder pagarlo.
        maxVotos = 0;
        subObjIndex = 0;
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.Aprobado && subObjetivos[i].monto <= ahorroActual){
              if(subObjetivos[i].cantVotos > maxVotos) {
                  maxVotos = subObjetivos[i].cantVotos;
                  subObjIndex = i;
              }
            }
        }
        // En caso de encontrarlo, se le cambia el estado a pendiente de ejecucion y se retorna la descripcion
        if(maxVotos > 0) {
            subObjetivos[subObjIndex].estado = Estado.PendienteEjecucion;
            return string(abi.encodePacked(subObjetivos[subObjIndex].descripcion, " (pendiente de ejecucion)"));
        }
    }

    //////////////////////////////////////////
    ///////// Funciones Auxiliares ///////////
    //////////////////////////////////////////

    function isInAhorristasMapping(address unAddress) private view returns(bool)
    {
        return ahorristas[unAddress].cuentaEth != address(0);
    }

    // Endpoint
    /* Devuelve si el ahorrista que realiza el request, tiene cuenta activa */
    function tieneCtaActiva(address adrs) private view returns (bool) {
        return ahorristas[adrs].banderas.isActive == true;
    }
    
    //////////////////////////////////////////
    ////////// METODOS DE PRUEBA /////////////
    //////////////////////////////////////////
    
    // Endpoint
    function setGestorTrue() public {
        bool currentState = ahorristas[msg.sender].banderas.isGestor;
        if(!currentState){
            cantAhorristasAproved++;
            cantGestores++;
            ahorristas[msg.sender].banderas.isGestor = true;
            ahorristas[msg.sender].banderas.isAproved = true;
            ahorroActual += ahorristas[msg.sender].montoAhorro;
        }
    }

    // Endpoint
    function setAuditorTrue() public {
        bool currentState = ahorristas[msg.sender].banderas.isAuditor;
        if(!currentState){
            cantAhorristasAproved++;
            cantAuditores++;
            ahorristas[msg.sender].banderas.isAuditor = true;
            ahorristas[msg.sender].banderas.isAproved = true;
            ahorroActual += ahorristas[msg.sender].montoAhorro;
        }
    }
    
    // Endpoint
    function setActive(bool activeStatus) public returns(bool) {
        address ads = msg.sender;
        ahorristas[ads].banderas.isActive = activeStatus;
        return true;
    }

    // Endpoint
    function getVotacionActiva() public view returns(bool) {
        return votacionActiva;
    }

    // Endpoint
    function setVotacionActiva(bool state) public {
        votacionActiva = state;
    }

    // Endpoint
    function getAhorrista(address ads) public view returns(Ahorrista memory){
        return ahorristas[ads];
    }

    // Endpoint
    function getAhorristas() public view returns(Ahorrista[] memory){
        Ahorrista[] memory memoryArray = new Ahorrista[](cantAhorristas);
        for(uint i = 0; i < cantAhorristas; i++) {
            memoryArray[i] = ahorristas[ahorristasIndex[i]];
        }
        return memoryArray;
    }

    // Endpoint
    function savingAccountStatePart1() public view returns(uint, uint, string memory, uint, uint, bool, bool, uint) {
        uint v1 = cantMaxAhorristas;
        uint v2 = ahorroObjetivo;
        string memory v3 = objetivo;
        uint v4 = minAporteDeposito;
        uint v5 = minAporteActivarCta;
        bool v6 = ahorroActualVisiblePorAhorristas;
        bool v7 = ahorroActualVisiblePorGestores;
        uint v8 = cantAhorristas;
        return (v1, v2, v3, v4, v5, v6, v7, v8);
    }

    // Endpoint
    function savingAccountStatePart2() public view returns(uint, uint, uint, uint, address, bool, uint, uint) {
        uint v9 = cantAhorristasActivos;
        uint v10 = cantAhorristasAproved;
        uint v11 = cantGestores;
        uint v12 = cantAuditores;
        address v13 = administrador;
        bool v14 = isActive;
        uint v15 = ahorroActual;
        uint v16 = totalRecibidoDeposito;
        return (v9, v10, v11, v12, v13, v14, v15, v16);
    }

    // Endpoint
    function getSubObjetivos() public view returns(SubObjetivo[] memory){
        return subObjetivos;
    }

    // Endpoint
    function getRealBalance() public view returns(uint) {
        return address(this).balance;
    }

}
