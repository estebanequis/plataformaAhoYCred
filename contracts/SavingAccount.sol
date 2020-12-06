//SPDX-License-Identifier:MIT;
pragma solidity ^0.6.1;

pragma experimental ABIEncoderV2;
import './GeneralConfiguration.sol';

contract SavingAccount {
    
    GeneralConfiguration public generalConf;
    address payable public administrador;
    bool public isActive;
    uint ahorroActual;
    uint ahorroObjetivo;
    string objetivo;
    uint minAporteDeposito;
    uint pctDtoAporteAudGest;
    uint minAporteActivarCta;
    uint totalRecibidoDeposito;         //no me queda claro para que sirve
    uint plazoSinRecargo = 40;          // Se debe indicar los segundos necesarios para que no se cobren recargos entre depositos, (5184000 son 60 dias)
    uint montoRecargo;
    uint pctAlAbandonar;                // Porcentaje de retiro al abandonar el contrato

    uint cantMaxAhorristas;
    uint cantAhorristas;                // Incluye todos (Ahorristas, Auditores, Gestores y Admin)
    uint cantAhorristasActivos;         // Incluye activos (sin importar si estan aprobados o no)
    uint cantAhorristasAproved;         // Solo los ahorristas isAproved == true
    uint cantGestores;
    uint cantAuditores;
    mapping(address => Ahorrista) public ahorristas;
    mapping(uint => address) public ahorristasIndex;
    struct Ahorrista {
        string cedula;
        string nombreCompleto;
        uint fechaIngreso;
        address payable cuentaEth;
        address payable cuentaBeneficenciaEth;
        uint montoAhorro;               //si isActive == false -> seria el dinero que no se suma al ahorro total del contrato
        Prestamos prestamos;
        Banderas banderas;
    }
    
    struct Banderas {
        EstadoAhorrista estadoAhorrista;
        VotoSubObjetivos votoSubObjetivos;
        VotoRoles votoRoles;
        VisualizarAhorro visualizarAhorro;
        Fallecimiento fallecimiento;
        uint ultimoDeposito;
    }

    uint plazoRevocarFallecimiento;     // Plazo en el cual una persona puede revocar su fallecimiento
    struct Fallecimiento {
        bool isAlive;
        bool yaVoto;                    // En caso de que sea un Gestor, guarda si ya voto o no
        uint cantVotos;                 // Indica la cantidad de votos que tiene su fallecimiento
        uint fechaFallecimiento;        // Indica el timestamp del momento en el cual 2 Gestores votaron su fallecimiento
    }

    struct EstadoAhorrista {
        bool isGestor;
        bool isAuditor;
        bool isActive;
        bool isAproved;
    }

    bool votacionSubObjetivosActiva;   //bandera para indicar periodo de votacion activo
    struct VotoSubObjetivos {
        bool ahorristaVotaSubObjetivo;
        bool auditorCierraVotacion;
        bool gestorVotaEjecucion;
    }

    struct VotoRoles {
        bool votoAGestor;
        bool votoAAuditor;
        bool postuladoComoGestor;
        bool postuladoComoAuditor;
        uint votosRecibidoComoGestor;
        uint votosRecibidoComoAuditor;
    }

    bool ahorroActualVisiblePorAhorristas;
    bool ahorroActualVisiblePorGestores;
    struct VisualizarAhorro {
        bool solicitoVerAhorro;
        bool tienePermiso;
    }

    uint pctMaxPrestamo;
    struct Prestamos {
        bool solicitoPrestamo;
        uint montoSolicitado;
        uint montoAdeudado;
    }

    enum EstadoVotacionRoles {Cerrado, Postulacion, Votacion}
    EstadoVotacionRoles estadoVotacionRoles;
    
    enum Estado {EnProcesoDeVotacion, Aprobado, PendienteEjecucion, Ejecutado}
    
    SubObjetivo[] public subObjetivos;
    struct SubObjetivo {
        string descripcion;
        uint monto;
        Estado estado;
        address payable ctaDestino;
        uint cantVotos;
    }

    modifier onlyAdmin() {
        require(msg.sender == administrador, 'Not the Admin');
        _;
    }
    
    modifier onlyAhorrista() {
        require(isInAhorristasMapping(msg.sender) == true, 'Not an Ahorrista');
        _;
    }

    modifier NotGestorOrAuditorOrAdmin() {
        require(isInAhorristasMapping(msg.sender) == true, 'No es un ahorrista');
        require(msg.sender != administrador, 'No puede ser Administrador');
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor == false, 'No puede ser Auditor');
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isGestor == false, 'No puede ser Gestor');
        _;
    }
    
    modifier onlyAuditor() {
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor == true, 'Not an Auditor');
        _;
    }
    
    modifier onlyAdminOrAuditor() {
        require(msg.sender == administrador || ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor == true, 'Not an Admin or an Auditor');
        _;
    }
    
    modifier onlyGestor() {
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isGestor == true, 'Not an Gestor');
        _;
    }
    
    modifier savingContractIsActive() {
        require(isActive == true, 'Saving Acccount Contract not active');
        _;
    }
    
    constructor() public {   
        administrador = msg.sender;
    }

    function setConfigAddress( GeneralConfiguration _address ) public {
        generalConf = _address;
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

    // Item 7 y 9
    function init(uint maxAhorristas, uint ahorroObj, string memory elObjetivo, uint minAporteDep, uint minAporteActivar, bool ahorristaVeAhorroActual, bool gestorVeAhorroActual, uint recargo, uint pMaxPrestamo, uint pDtoAporteAudGest, uint pAlAbandonar, uint pzoRevocarFallecimiento) public onlyAdmin {
        require(maxAhorristas >= 6, "maxAhorristas must be greater than 5");
        require(minAporteDep >= 0, "minAporteDep must be a positive value"); //ver si sirve
        require(bytes(elObjetivo).length != 0, "elObjetivo must be specified");
        require(pMaxPrestamo <= 100 && pDtoAporteAudGest <= 100 && pAlAbandonar <= 100, "Pct invalido.");
        cantMaxAhorristas = maxAhorristas;
        ahorroObjetivo = ahorroObj;
        objetivo = elObjetivo;
        minAporteDeposito = minAporteDep;
        minAporteActivarCta = minAporteActivar;
        ahorroActualVisiblePorAhorristas = ahorristaVeAhorroActual;
        ahorroActualVisiblePorGestores = gestorVeAhorroActual;
        estadoVotacionRoles = EstadoVotacionRoles.Cerrado;
        montoRecargo = recargo;
        pctMaxPrestamo = pMaxPrestamo;
        pctDtoAporteAudGest = pDtoAporteAudGest;
        pctAlAbandonar = pAlAbandonar;
        plazoRevocarFallecimiento = pzoRevocarFallecimiento;
    }

    // Item 8 y 10
    function sendDepositWithRegistration(string memory cedula, string memory fullName, address payable addressBeneficiario) public payable {
        require(msg.value >= minAporteDeposito, 'Monto insuficiente');
        address payable addressUser = msg.sender;
        if (!isInAhorristasMapping(addressUser)) {
            ahorristas[addressUser].cedula = cedula;
            ahorristas[addressUser].nombreCompleto = fullName;
            ahorristas[addressUser].fechaIngreso = block.timestamp;
            ahorristas[addressUser].cuentaEth = addressUser;
            ahorristas[addressUser].cuentaBeneficenciaEth = addressBeneficiario;
            ahorristas[addressUser].montoAhorro = msg.value;
            ahorristas[addressUser].prestamos = Prestamos(false,0,0);
            ahorristas[addressUser].banderas = Banderas(EstadoAhorrista(false,false,false,false),VotoSubObjetivos(false,false,false),VotoRoles(false,false,false,false,0,0),VisualizarAhorro(false,false),Fallecimiento(true,false,0,0),0);
            ahorristasIndex[cantAhorristas] = addressUser;
            cantAhorristas++;
            if(msg.value >= minAporteActivarCta) {
                ahorristas[addressUser].banderas.estadoAhorrista.isActive = true;
                ahorristas[addressUser].banderas.ultimoDeposito = block.timestamp;
                cantAhorristasActivos++;
            }
        }
    }
    
    // Item 6, 8 
    function sendDeposit() public payable savingContractIsActive {
        require(isInAhorristasMapping(msg.sender), "No existe ahorrista.");
        require((block.timestamp - ahorristas[msg.sender].banderas.ultimoDeposito) <= plazoSinRecargo, "El plazo sin recargo fue superado, debe pagar el recargo para poder depositar.");
        require(msg.value >= minAporteDeposito ||
            (ahorristas[msg.sender].banderas.estadoAhorrista.isGestor && msg.value >= (minAporteDeposito*(100-pctDtoAporteAudGest))/100) ||
            (ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor && msg.value >= (minAporteDeposito*(100-pctDtoAporteAudGest))/100), "Aporte no valido.");
        ahorristas[msg.sender].montoAhorro += msg.value;
        ahorristas[msg.sender].banderas.ultimoDeposito = block.timestamp;
        if (ahorristas[msg.sender].banderas.estadoAhorrista.isAproved) {
            ahorroActual += msg.value;
        } else if(!ahorristas[msg.sender].banderas.estadoAhorrista.isActive && ahorristas[msg.sender].montoAhorro >= minAporteActivarCta){
            ahorristas[msg.sender].banderas.estadoAhorrista.isActive = true;
            cantAhorristasActivos++;
        }
    }
    
    // Item 10
    function aproveAhorrista(address unAddress) public onlyAuditor returns (bool) {
        bool retorno = false;
        if (isInAhorristasMapping(unAddress) && ahorristas[unAddress].banderas.estadoAhorrista.isActive == true) {
            if (isActive == false) {
                ahorristas[unAddress].banderas.estadoAhorrista.isAproved = true;
                cantAhorristasAproved++;
                ahorroActual += ahorristas[unAddress].montoAhorro;
                retorno = true; 
            }
            else if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, cantAuditores)) {
                ahorristas[unAddress].banderas.estadoAhorrista.isAproved = true;
                cantAhorristasAproved++;
                ahorroActual += ahorristas[unAddress].montoAhorro;
                retorno = true;
            }  
        }
        return retorno;
    }
    
    //////////////////////////////////////////
    ////////// Items 11 al 17 ////////////////
    /////// Votacion de Subobjetivos /////////
    //////////////////////////////////////////
    
    /* El Admin puede agregar un SubObjetivo */
    function addSubObjetivo(string memory desc, uint monto, address payable ctaDestino) public onlyAdmin {
        Estado estado = Estado(0);
        subObjetivos.push(SubObjetivo(desc, monto, estado, ctaDestino, 0));
    }

    /* En caso de que exista al menos 1 SubObjetivo con estado EnProcesoDeVotacion
    Se habilitara el periodo de votacion */
    function habilitarPeriodoDeVotacion() public onlyAdmin returns(bool) {
        // Se resetean las banderas
        for(uint i=0; i<cantAhorristas; i++) {
            ahorristas[ahorristasIndex[i]].banderas.votoSubObjetivos.ahorristaVotaSubObjetivo = false;
            ahorristas[ahorristasIndex[i]].banderas.votoSubObjetivos.auditorCierraVotacion = false;
        }
        // Se fija si existe al menos un SubObjetivo con estado EnProcesoDeVotacion En caso de encontrarlo, activa la votacion
        for(uint i=0; i<subObjetivos.length; i++) {
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion) {
                votacionSubObjetivosActiva = true;
                return true;
            }
        }
        return false;
    }

    /* Todos los ahorristas con cuentas activas pueden votar durante el periodo de votacion una unica vez */
    function votarSubObjetivoEnProesoDeVotacion(string memory descripcion) public onlyAhorrista returns(string memory) {
        require(votacionSubObjetivosActiva == true, 'No existe periodo de votacion abierto.');
        require(tieneCtaActiva(msg.sender) == true, 'Su cuenta no esta activa, no puede votar.');
        require(ahorristas[msg.sender].banderas.votoSubObjetivos.ahorristaVotaSubObjetivo == false, 'Ya ha votado.');
        // Buscamos los SubObjetivos con estado EnProcesoDeVotacion.
        // Si existe alguno con la misma descripcion ingresada, se le agrega un voto
        // Y se marca al ahorrista como que ha votado.
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion){
                if(keccak256(abi.encodePacked(subObjetivos[i].descripcion)) == keccak256(abi.encodePacked(descripcion))){
                    subObjetivos[i].cantVotos++;
                    ahorristas[msg.sender].banderas.votoSubObjetivos.ahorristaVotaSubObjetivo = true;
                    return "OK";
                }         
            }
        }
        return "No se encontro el subobjetivo";
    }

    /* Los auditores pueden votar para cerrar el periodo de votacion */
    function votarCerrarPeriodoDeVotacion() public onlyAuditor returns(string memory) {
        if(votacionSubObjetivosActiva == false) { return "No existe periodo de votacion abierto"; }
        // Se agrega el voto al auditor que llamo al metodo
        ahorristas[msg.sender].banderas.votoSubObjetivos.auditorCierraVotacion = true;
        // Buscamos si existe algun auditor sin votar
        for(uint i=0; i<cantAhorristas; i++) {
            if (ahorristas[ahorristasIndex[i]].banderas.votoSubObjetivos.auditorCierraVotacion == false && ahorristas[ahorristasIndex[i]].banderas.estadoAhorrista.isAuditor == true) {
                return "Se ha agregado su voto pero faltan Auditores por votar";
            }
        }
        // Como todos los auditores votaron cerrar el periodo, se cierra la votacion
        votacionSubObjetivosActiva = false;
        // Todos los SubObjetivos que tuvieron votos, se pasan a estado Aprobado
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.EnProcesoDeVotacion && subObjetivos[i].cantVotos > 0){
               subObjetivos[i].estado = Estado.Aprobado;
            }
        }
        return "El periodo de votacion ha quedado cerrado";
    }

    /* Los gestores pueden votar un SubObjetivo */
    function votarSubObjetivoPendienteEjecucion(string memory descripcion) public onlyGestor returns(string memory){ 
        require(ahorristas[msg.sender].banderas.votoSubObjetivos.gestorVotaEjecucion == false, 'Ya has votado.');
        // Se busca en la lista de SubObjetivos los SubObjetivos pendientes de ejecucion
        for(uint i=0; i<subObjetivos.length; i++) { 
            if(subObjetivos[i].estado == Estado.PendienteEjecucion){
                // Si se encuentra uno con la misma descripcion del request, se le agrega el voto al Gestor
                if(keccak256(abi.encodePacked(subObjetivos[i].descripcion)) == keccak256(abi.encodePacked(descripcion))){
                    ahorristas[msg.sender].banderas.votoSubObjetivos.gestorVotaEjecucion = true;
                    uint cantGestoresAprobaron = 0;
                    // Se busca la cantidad de Gestores que han votado la ejecucion hasta el momento
                    for(uint j=0; j<cantAhorristas; j++) {
                        if (ahorristas[ahorristasIndex[j]].banderas.estadoAhorrista.isGestor == true && ahorristas[ahorristasIndex[j]].banderas.votoSubObjetivos.gestorVotaEjecucion == true){
                            cantGestoresAprobaron++;
                        }
                    }
                    // Si ya existia otro Gestor que voto la ejecucion, entonces se ejecuta el SubObjetivo
                    if(cantGestoresAprobaron >= 2) {
                        ejecutarSubObjetivo(i);
                        // Se resetean las banderas de votos de los gestores
                        for(uint k=0; k<cantAhorristas; k++) {
                            ahorristas[ahorristasIndex[k]].banderas.votoSubObjetivos.gestorVotaEjecucion = false;
                        }
                        return string(abi.encodePacked("Se ejecuto el SubObjetivo ", subObjetivos[i].descripcion));
                    }
                    return "Se ha agregado su voto pero todavia falta un Gestor por votar";
                }         
            }
        }
        return "No se encontro el subobjetivo";
    }
    
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

    // TODO: No se transfieren realmente los weis hacia afuera
    /* Ejecuta un SubObjetivo segun su index en la lista de SubObjetivos */
    function ejecutarSubObjetivo(uint index) private {
        subObjetivos[index].estado = Estado.Ejecutado;
        ahorroActual = ahorroActual - subObjetivos[index].monto;
        subObjetivos[index].ctaDestino.transfer(subObjetivos[index].monto);
        ejecutarSubObjetivoEvent(index, msg.sender);
    }

    // Probar
    event SubObjetivoEvent(address indexed gestorAdrs, string indexed descripcion, uint monto, address ctaDestino);
    function ejecutarSubObjetivoEvent(uint subObjIndex, address gestorAdrs) public {
        emit SubObjetivoEvent(
            gestorAdrs,
            subObjetivos[subObjIndex].descripcion,
            subObjetivos[subObjIndex].monto,
            subObjetivos[subObjIndex].ctaDestino
        );
    }

    //////////////////////////////////////////
    ///////////// Items 19 al 21 /////////////
    /////////// Votacion de Roles ////////////
    //////////////////////////////////////////

    function habilitarPostulacionDeCandidatos() public onlyAdmin {
        require(estadoVotacionRoles == EstadoVotacionRoles.Cerrado, "Para habilitar la postulacion de candidatos, el estado acual debe ser cerrado.");
        require(isActive == true, "El contrato debe estar activo para poder habilitar la postulacion de candidatos.");
        require(cantAhorristasAproved >= 6, "El contrato debe tener al menos 6 ahorristas aprobados para habilitar la postulacion de candidatos.");
        estadoVotacionRoles = EstadoVotacionRoles.Postulacion;
    }

    function postularseComoGestor() public NotGestorOrAuditorOrAdmin {
        require(estadoVotacionRoles == EstadoVotacionRoles.Postulacion, "Para poder postularse, el estado de la votacion debe ser de postulacion.");
        require(tieneCtaActiva(msg.sender), "Para poder postularse, debes tener la cuenta de ahorro activa.");
        ahorristas[msg.sender].banderas.votoRoles.postuladoComoGestor = true;
    }

    function postularseComoAuditor() public NotGestorOrAuditorOrAdmin {
        require(estadoVotacionRoles == EstadoVotacionRoles.Postulacion, "Para poder postularse, el estado de la votacion debe ser de postulacion.");
        require(tieneCtaActiva(msg.sender), "Para poder postularse, debes tener la cuenta de ahorro activa.");
        ahorristas[msg.sender].banderas.votoRoles.postuladoComoAuditor = true;
    }

    function habilitarVotoDeCandidatos() public onlyAdmin {
        require(estadoVotacionRoles == EstadoVotacionRoles.Postulacion, "Para habilitar la votacion de candidatos, el estado acual debe ser postulacion.");
        estadoVotacionRoles = EstadoVotacionRoles.Votacion;
    }

    function votarGestor(address gestorAdrs) onlyAhorrista public {
        require(tieneCtaActiva(msg.sender), "Para votar, es necesario que su cuenta este activa.");
        require(ahorristas[msg.sender].banderas.votoRoles.votoAGestor == false, "Ya ha votado un Gestor.");
        require(ahorristas[gestorAdrs].banderas.votoRoles.postuladoComoGestor == true, "No esta postulado como Gestor.");
        require(estadoVotacionRoles == EstadoVotacionRoles.Votacion, "Para poder votar, el estado acual debe ser votacion.");
        ahorristas[msg.sender].banderas.votoRoles.votoAGestor = true;
        ahorristas[gestorAdrs].banderas.votoRoles.votosRecibidoComoGestor++;
    }

    function votarAuditor(address auditorAdrs) onlyAhorrista public {
        require(tieneCtaActiva(msg.sender), "Para votar, es necesario que su cuenta este activa.");
        require(ahorristas[msg.sender].banderas.votoRoles.votoAAuditor == false, "Ya ha votado un Auditor.");
        require(ahorristas[auditorAdrs].banderas.votoRoles.postuladoComoAuditor == true, "No esta postulado como Auditor.");
        require(estadoVotacionRoles == EstadoVotacionRoles.Votacion, "Para poder votar, el estado acual debe ser votacion.");
        ahorristas[msg.sender].banderas.votoRoles.votoAAuditor = true;
        ahorristas[auditorAdrs].banderas.votoRoles.votosRecibidoComoAuditor++;
    }

    function cerrarVotoDeCandidatos() public onlyAdmin {
        require(estadoVotacionRoles == EstadoVotacionRoles.Votacion, "Para cerrar la votacion de candidatos, el estado acual debe ser votacion.");
        asignarRolesPorVotos();
        estadoVotacionRoles = EstadoVotacionRoles.Cerrado;
        resetearVotoRoles();
    }

    function asignarRolesPorVotos() private returns(bool) {
        uint maxVotosAuditor = 0;
        address addressMaxVotosAuditor;
        uint segMaxVotosAuditor = 0;
        address addressSegMaxVotosAuditor;
        uint maxVotosGestor = 0;
        address addressMaxVotosGestor;
        uint segMaxVotosGestor = 0;
        address addressSegMaxVotosGestor;
        for(uint i=0; i<cantAhorristas; i++) { 
            address addressAhorrista = ahorristas[ahorristasIndex[i]].cuentaEth;
            uint votosComoAuditor = ahorristas[ahorristasIndex[i]].banderas.votoRoles.votosRecibidoComoAuditor;
            if(votosComoAuditor > maxVotosAuditor) {
                maxVotosAuditor = votosComoAuditor;
                addressMaxVotosAuditor = addressAhorrista;
            } else if (votosComoAuditor > segMaxVotosAuditor) {
                segMaxVotosAuditor = votosComoAuditor;
                addressSegMaxVotosAuditor = addressAhorrista;
            }
            uint votosComoGestor = ahorristas[ahorristasIndex[i]].banderas.votoRoles.votosRecibidoComoGestor;
            if(votosComoGestor > maxVotosGestor) {
                maxVotosGestor = votosComoGestor;
                addressMaxVotosGestor = addressAhorrista;
            } else if (votosComoGestor > segMaxVotosGestor) {
                segMaxVotosGestor = votosComoGestor;
                addressSegMaxVotosGestor = addressAhorrista;
            }
        }
        if ((addressMaxVotosAuditor == address(0)) && (addressMaxVotosGestor == address(0))) {
            return false;
        }
        if ((addressMaxVotosAuditor != address(0)) && (addressMaxVotosGestor == address(0))) {
            if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, (cantAuditores+1))) {
                ahorristas[addressMaxVotosAuditor].banderas.estadoAhorrista.isAuditor = true;
                cantAuditores++;
                return true;
            }
            return false;
        }
        if ((addressMaxVotosAuditor == address(0)) && (addressMaxVotosGestor != address(0))) {
            if (generalConf.validateRestrictions(cantAhorristasAproved, (cantGestores+1), cantAuditores)) {
                ahorristas[addressMaxVotosGestor].banderas.estadoAhorrista.isGestor = true;
                cantGestores++;
                return true;
            }
            return false;
        }
        // Si son diferentes address, te quedas con el Auditor que tuvo mas votos y con el Gestor que tuvo mas votos
        if ((addressMaxVotosAuditor != addressMaxVotosGestor)) {
            if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, (cantAuditores+1))) {
                ahorristas[addressMaxVotosAuditor].banderas.estadoAhorrista.isAuditor = true;
                cantAuditores++;
            }
            if (generalConf.validateRestrictions(cantAhorristasAproved, (cantGestores+1), cantAuditores)) {
                ahorristas[addressMaxVotosGestor].banderas.estadoAhorrista.isGestor = true;
                cantGestores++;
            }
        // Si los address con mas votos son iguales, a ese address se le asigna el rol por el cual tuvo mas votos
        } else if (maxVotosAuditor >= maxVotosGestor) {
            if (generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, (cantAuditores+1))) {
                ahorristas[addressMaxVotosAuditor].banderas.estadoAhorrista.isAuditor = true;
                cantAuditores++;
            }
            if ((addressSegMaxVotosGestor != address(0)) && generalConf.validateRestrictions(cantAhorristasAproved, (cantGestores+1), cantAuditores)) {
                ahorristas[addressSegMaxVotosGestor].banderas.estadoAhorrista.isGestor = true;
                cantGestores++;
            }
        } else if (maxVotosGestor > maxVotosAuditor) {
            if (generalConf.validateRestrictions(cantAhorristasAproved, (cantGestores+1), cantAuditores)) {
                ahorristas[addressMaxVotosGestor].banderas.estadoAhorrista.isGestor = true;
                cantGestores++;
            }
            if ((addressSegMaxVotosAuditor != address(0)) && generalConf.validateRestrictions(cantAhorristasAproved, cantGestores, (cantAuditores+1))) {
                ahorristas[addressSegMaxVotosAuditor].banderas.estadoAhorrista.isAuditor = true;
                cantAuditores++;
            }
        }
        return true;
    }

    function resetearVotoRoles() private {
        for(uint i=0; i<cantAhorristas; i++) {
            ahorristas[ahorristasIndex[i]].banderas.votoRoles = VotoRoles(false, false, false, false, 0, 0);
        }
    }

    //////////////////////////////////////////
    ///////////// Items 22 al 23 /////////////
    //////////// Monto de ahorro /////////////
    //////////////////////////////////////////

    function getAhorroActual() public view returns (uint) {
        require(msg.sender == administrador 
            || ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor == true
            || ahorristas[msg.sender].banderas.visualizarAhorro.tienePermiso == true,
            "No tiene permiso para poder ver el monto de ahorro actual.");
        return ahorroActual;
    }

    function solicitarVerMontoAhorro() public onlyAhorrista {
        require(msg.sender != administrador, 'Ya tiene permitido ver el monto de ahorro actual.');
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor == false, 'Ya tiene permitido ver el monto de ahorro actual.');
        ahorristas[msg.sender].banderas.visualizarAhorro.solicitoVerAhorro = true;
    }

    function permitirVerMontoAhorro(address ahorristaAdrs) public onlyAdminOrAuditor {
        require(ahorristas[ahorristaAdrs].banderas.visualizarAhorro.solicitoVerAhorro == true, 'El ahorrista no solicito ver el monto de ahorro actual.');
        ahorristas[ahorristaAdrs].banderas.visualizarAhorro.tienePermiso = true;
    }

    function revocarVerMontoAhorro(address ahorristaAdrs) public onlyAdminOrAuditor {
        require(ahorristas[ahorristaAdrs].banderas.visualizarAhorro.tienePermiso == true, 'El ahorrista no tenia permisos para ver el monto de ahorro actual.');
        ahorristas[ahorristaAdrs].banderas.visualizarAhorro.solicitoVerAhorro = false;
        ahorristas[ahorristaAdrs].banderas.visualizarAhorro.tienePermiso = false;
    }

    //////////////////////////////////////////
    ///////////// Items 24 al 26 /////////////
    //////////////// Prestamos ///////////////
    //////////////////////////////////////////

    function solicitarPrestamo(uint montoSolicitado) public onlyAhorrista {
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isActive == true, "Debes estar activo para solicitar un prestamo.");
        require(montoSolicitado <= (ahorroActual*pctMaxPrestamo)/100, "El monto solicitado no debe ser mayor al porcentaje maximo permitido para prestamos.");
        ahorristas[msg.sender].prestamos.solicitoPrestamo = true;
        ahorristas[msg.sender].prestamos.montoSolicitado = montoSolicitado;
    }

    // TODO: No se transfieren realmente los weis hacia afuera
    function adjudicarPrestamo(address ahorristaAdrs) public onlyAuditor {
        require(ahorristas[ahorristaAdrs].prestamos.solicitoPrestamo == true, "El ahorrista no ha solicitado un prestamo.");
        ahorristas[ahorristaAdrs].banderas.estadoAhorrista.isActive = false;
        ahorristas[ahorristaAdrs].prestamos.solicitoPrestamo = false;
        ahorristas[ahorristaAdrs].cuentaEth.transfer(ahorristas[ahorristaAdrs].prestamos.montoSolicitado);
        ahorristas[ahorristaAdrs].prestamos.montoAdeudado = ahorristas[ahorristaAdrs].prestamos.montoSolicitado;
        ejecutarPrestamoEvent(ahorristaAdrs, ahorristas[ahorristaAdrs].prestamos.montoSolicitado);
    }

    function pagarPrestamo() payable public onlyAhorrista {
        require(ahorristas[msg.sender].banderas.estadoAhorrista.isActive == false, "Debes estar inactivo para pagar un prestamo.");
        require(msg.value <= ahorristas[msg.sender].prestamos.montoAdeudado, "El monto que puedes pagar debe ser menor o igual a lo que adeudas.");
        ahorristas[msg.sender].prestamos.montoAdeudado -= msg.value;
        if (ahorristas[msg.sender].prestamos.montoAdeudado == 0) {
            ahorristas[msg.sender].banderas.estadoAhorrista.isActive = true;
            ahorristas[msg.sender].prestamos.montoSolicitado = 0;
            ahorristas[msg.sender].prestamos.montoAdeudado = 0;
        }
    }

    // Probar
    event PrestamoEvent(address indexed ahorristaAdrs, uint monto);
    function ejecutarPrestamoEvent(address ahorristaAdrs, uint monto) public {
        emit PrestamoEvent(
            ahorristaAdrs,
            monto
        );
    }

    //////////////////////////////////////////
    //////////////// Item 27 /////////////////
    /////////// Plazo de deposito ////////////
    //////////////////////////////////////////

    function pagarRecargo() payable public onlyAhorrista savingContractIsActive {
        require((block.timestamp - ahorristas[msg.sender].banderas.ultimoDeposito) > plazoSinRecargo, "No es necesario pagar recargos para realizar un deposito.");
        require(msg.value == montoRecargo, "El valor no es igual al monto de recargo establecido");
        ahorristas[msg.sender].banderas.ultimoDeposito = block.timestamp;
        ahorroActual += msg.value;
    }

    //////////////////////////////////////////
    ///////////// Items 28 al 29 /////////////
    //////////////// Abandonar ///////////////
    //////////////////////////////////////////

    // TODO: No se transfieren realmente los weis hacia afuera
    function abandonarContrato(bool conRetiro) public onlyAhorrista {
        require(msg.sender != administrador, "No se puede retirar");
        if (conRetiro == true) {
            require(tieneCtaActiva(msg.sender), "No tiene cuenta activa.");
            require(ahorristas[msg.sender].prestamos.montoAdeudado == 0, "Mantiene deudas.");
            uint montoRetiro = (ahorristas[msg.sender].montoAhorro*pctAlAbandonar)/100;
            ahorristas[msg.sender].cuentaEth.transfer(montoRetiro);
            ahorroActual -= montoRetiro;
        }
        if (ahorristas[msg.sender].banderas.estadoAhorrista.isActive) cantAhorristasActivos--; 
        if (ahorristas[msg.sender].banderas.estadoAhorrista.isAproved) cantAhorristasAproved--;
        borrarAhorrista(msg.sender);
    }

    function getAhorristaIndexByAddress(address adrs) private view returns(uint) {
        uint retorno = 0;
        for(uint i=0; i<cantAhorristas; i++) {
            if(ahorristasIndex[i] == adrs) {
                retorno = i;
            }
        }
        return retorno;
    }

    function borrarAhorrista(address adrs) private {
        ahorristasIndex[getAhorristaIndexByAddress(adrs)] = ahorristasIndex[cantAhorristas-1];
        ahorristasIndex[cantAhorristas-1] = address(0);
        cantAhorristas--;
        if (ahorristas[adrs].banderas.estadoAhorrista.isAuditor) {
            cantAuditores--;
            if (generalConf.isValid(cantAhorristasAproved, cantGestores, cantAuditores) == false) {
                if (estadoVotacionRoles == EstadoVotacionRoles.Cerrado) estadoVotacionRoles = EstadoVotacionRoles.Postulacion;
            }
        } 
        if (ahorristas[adrs].banderas.estadoAhorrista.isGestor) {
            cantGestores--;
            if (generalConf.isValid(cantAhorristasAproved, cantGestores, cantAuditores) == false) {
                if (estadoVotacionRoles == EstadoVotacionRoles.Cerrado) estadoVotacionRoles = EstadoVotacionRoles.Postulacion;
            }
        }
        delete ahorristas[adrs];
    }

    //////////////////////////////////////////
    /////////// Items 30, 31 y 33 ////////////
    ///////////// Fallecimiento //////////////
    //////////////////////////////////////////

    function votarFallecimiento(address adrs) public onlyGestor {
        require(ahorristas[msg.sender].banderas.fallecimiento.isAlive == true, "No se encuentra vivo.");
        require(ahorristas[msg.sender].banderas.fallecimiento.yaVoto == false, "Ya voto.");
        ahorristas[adrs].banderas.fallecimiento.cantVotos++;
        ahorristas[msg.sender].banderas.fallecimiento.yaVoto = true;
        if (ahorristas[adrs].banderas.fallecimiento.cantVotos >= 2) {
            ahorristas[adrs].banderas.fallecimiento.isAlive = false;
            ahorristas[adrs].banderas.fallecimiento.fechaFallecimiento = block.timestamp;
        } 
    } 

    function revocarFallecimiento() public onlyAhorrista {
        require(ahorristas[msg.sender].banderas.fallecimiento.isAlive == false, "No se encuentra fallecido.");
        require(block.timestamp <= ahorristas[msg.sender].banderas.fallecimiento.fechaFallecimiento + plazoRevocarFallecimiento, "Supero el plazo.");
        resetFallecimientos();
    }

    function liquidarCuentaAhorro(address adrs) public onlyAuditor {
        require(ahorristas[adrs].banderas.fallecimiento.isAlive == false, "No fallecio");
        require(block.timestamp > ahorristas[adrs].banderas.fallecimiento.fechaFallecimiento + plazoRevocarFallecimiento, "No supero el plazo.");
        uint montoLiquidacion = (ahorristas[adrs].montoAhorro*pctAlAbandonar)/100;
        ahorristas[adrs].cuentaBeneficenciaEth.transfer(montoLiquidacion);
        ahorroActual -= montoLiquidacion;
        borrarAhorrista(adrs);
        resetFallecimientos();
    }

    function resetFallecimientos() private {
        for(uint i=0; i<cantAhorristas; i++) {
            ahorristas[ahorristasIndex[i]].banderas.fallecimiento = Fallecimiento(true, false, 0, 0);
        }
    }

    //////////////////////////////////////////
    ///////////// Items 34 y 35 //////////////
    /////////// Liquidar Contrato ////////////
    //////////////////////////////////////////



    //////////////////////////////////////////
    ///////// Funciones Auxiliares ///////////
    //////////////////////////////////////////

    function isInAhorristasMapping(address unAddress) private view returns(bool) {
        return ahorristas[unAddress].cuentaEth != address(0);
    }

    /* Devuelve si el ahorrista que realiza el request, tiene cuenta activa */
    function tieneCtaActiva(address adrs) private view returns (bool) {
        return ahorristas[adrs].banderas.estadoAhorrista.isActive == true;
    }
    
    //////////////////////////////////////////
    ////////// METODOS DE PRUEBA /////////////
    //////////////////////////////////////////
    
    function setGestorTrue() public {
        bool currentState = ahorristas[msg.sender].banderas.estadoAhorrista.isGestor;
        if(!currentState){
            cantAhorristasAproved++;
            cantGestores++;
            ahorristas[msg.sender].banderas.estadoAhorrista.isGestor = true;
            ahorristas[msg.sender].banderas.estadoAhorrista.isAproved = true;
            ahorroActual += ahorristas[msg.sender].montoAhorro;
        }
    }

    function setAuditorTrue() public {
        bool currentState = ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor;
        if(!currentState){
            cantAhorristasAproved++;
            cantAuditores++;
            ahorristas[msg.sender].banderas.estadoAhorrista.isAuditor = true;
            ahorristas[msg.sender].banderas.estadoAhorrista.isAproved = true;
            ahorroActual += ahorristas[msg.sender].montoAhorro;
        }
    }

/*
    function getAhorristas() public view returns(Ahorrista[] memory){
        Ahorrista[] memory memoryArray = new Ahorrista[](cantAhorristas);
        for(uint i = 0; i < cantAhorristas; i++) {
            memoryArray[i] = ahorristas[ahorristasIndex[i]];
        }
        return memoryArray;
    }
    */
    
/*
    function getRealBalance() public view returns(uint) {
        return address(this).balance;
    }
*/

/*
    function savingAccountStatePart1() public view returns(uint, uint, string memory, uint, uint, bool, bool, uint) {
        return (cantMaxAhorristas, ahorroObjetivo, objetivo, minAporteDeposito, minAporteActivarCta, ahorroActualVisiblePorAhorristas, ahorroActualVisiblePorGestores, cantAhorristas);
    }

    function savingAccountStatePart2() public view returns(uint, uint, uint, uint, address, bool, uint, uint) {
        return (cantAhorristasActivos, cantAhorristasAproved, cantGestores, cantAuditores, administrador, isActive, ahorroActual, totalRecibidoDeposito);
    }
*/

/*
    function getVotacionActiva() public view returns(bool) {
        return votacionSubObjetivosActiva;
    }

    function getSubObjetivos() public view returns(SubObjetivo[] memory){
        return subObjetivos;
    }
*/

/*
    function getVotacionRolesState() public view returns(EstadoVotacionRoles) {
        return estadoVotacionRoles;
    }
*/

/*
    // Los gestores pueden obtener un listado de los SubObjetivos pendientes de ejecucion
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
*/

/*
    // Los ahorristas pueden obtener un listado de los SubObjetivos disponibles
    function getSubObjetivosEnProcesoDeVotacion() public onlyAhorrista view returns(string[] memory) {
        require(votacionSubObjetivosActiva == true, 'Para obtener la lista de SubObjetivos, es necesario que la votacion se encuentre activa.');
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
*/

/*
    function getAhorristasToAprove() public onlyAuditor view returns(address[] memory) {
        address[] memory losActivosSinAprobar = new address[](cantAhorristasActivos - cantAhorristasAproved);
        uint j = 0;
        if (cantAhorristasActivos - cantAhorristasAproved > 0) {
            for(uint i=0; i<cantAhorristas; i++) {
                if(ahorristas[ahorristasIndex[i]].banderas.estadoAhorrista.isActive && !ahorristas[ahorristasIndex[i]].banderas.estadoAhorrista.isAproved) {
                    losActivosSinAprobar[j] = ahorristas[ahorristasIndex[i]].cuentaEth;    
                    j++;
                }
            }
        }
        return losActivosSinAprobar;
    }
    */

}
