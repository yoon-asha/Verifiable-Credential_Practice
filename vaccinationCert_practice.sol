// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

abstract contract OwnerHelper {
    address private owner;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner {
		require(msg.sender == owner);
		_;
  	}

  	constructor() {
		owner = msg.sender;
  	}

  	function transferOwnership(address _to) onlyOwner public {
        require(_to != owner);
        require(_to != address(0x0));
    	owner = _to;
    	emit OwnerTransferPropose(owner, _to);
  	}
}

abstract contract IssuerHelper is OwnerHelper {
    mapping(address => bool) public issuers;

    event AddIssuer(address indexed _issuer);
    event DelIssuer(address indexed _issuer);

    modifier onlyIssuer {
        require(isIssuer(msg.sender) == true);
        _;
    }

    constructor() {
        issuers[msg.sender] = true;
    }

    function isIssuer(address _addr) public view returns (bool) {
        return issuers[_addr];
    }

    function addIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == false);
        issuers[_addr] = true;
        emit AddIssuer(_addr);
        return true;
    }

    function delIssuer(address _addr) onlyOwner public returns (bool) {
        require(issuers[_addr] == true);
        issuers[_addr] = false;
        emit DelIssuer(_addr);
        return true;
    }
}

contract CredentialBox is IssuerHelper {
    uint256 private idCount;
    mapping(uint8 => string) private vaccineEnum;
    mapping(uint8 => string) private statusEnum;

    struct Credential{
        uint256 id; // 
        address [] issuer; // 접종 기관(병원, 보건소) 
        uint8 [] vaccineType; // 접종한 백신 종류
        uint8 statusType; // 백신 접종 상태
        string [] value; // 암호화된 정보
        uint256 createDate; // 생성일자
    }

    mapping(address => Credential) private credentials;

    constructor() {
        idCount = 1;
        // 백신 종류
        vaccineEnum[0] = "Pfizer";
        vaccineEnum[1] = "Moderna";
        vaccineEnum[2] = "AstraZeneca";
        vaccineEnum[3] = "Janssen";
        // Novavax는 함수로 추가해주겠습니다

        // 백신 접종 상태
        statusEnum[0] = "unvax";
        statusEnum[1] = "vax";
        statusEnum[2] = "expvax";
    }

    function claimCredential(
        address _vaccineAddress, uint8 _vaccineType, 
        uint8 _statusType, string calldata _value
        ) onlyIssuer public returns(bool) {
            Credential storage credential = credentials[_vaccineAddress];
            require(credential.id == 0);
            credential.id = idCount;
            credential.issuer.push(msg.sender);
            credential.vaccineType.push(_vaccineType);
            credential.statusType = _statusType;
            credential.value.push(_value);
            credential.createDate = block.timestamp;

            idCount += 1;

            return true;
    }

    function getCredential(address _vaccineAddress) public view returns (Credential memory){
        Credential storage credential = credentials[_vaccineAddress];
        require(credential.id != 0);
        return credentials[_vaccineAddress];
    }

    function getVaccineType(uint8 _type) public view returns (string memory) {
        return vaccineEnum[_type];
    }

    function getStatusType(uint8 _type) public view returns (string memory) {
        return statusEnum[_type];
    }

// vaccineType 추가
    function addVaccineType(uint8 _type, string calldata _value) onlyIssuer public returns (bool) {
        require(bytes(vaccineEnum[_type]).length == 0);
        vaccineEnum[_type] = _value;
        return true;
    }

// statusType을 추가할 일이 있을까 싶지만....
    function addStatusType(uint8 _type, string calldata _value) onlyIssuer public returns (bool){
        require(bytes(statusEnum[_type]).length == 0);
        statusEnum[_type] = _value;
        return true;
    }

// 접종 상태 변경
    function changeStatus(address _vaccine, uint8 _type) onlyIssuer public returns (bool) {
        require(credentials[_vaccine].id != 0);
        require(bytes(statusEnum[_type]).length != 0);
        credentials[_vaccine].statusType = _type;
        return true;
    }
// 접종 상태 삭제!
    function removeStatus(address _vaccine, uint8 _type) onlyIssuer public returns (bool){
        require(credentials[_vaccine].id != 0);
        statusEnum[_type] = "";
        return true;
    }
}