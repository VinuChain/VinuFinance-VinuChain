import * as fs from "fs";

const addTimestampSupport = (contractSrc) => {
    contractSrc = contractSrc.replace('// TMP-TIMESTAMP-METHODS', `
    uint32 time;
    function setTime(uint32 _time) external { time = _time; }
    function getTime() public view returns (uint32) { return time; } 
    `)
    contractSrc = contractSrc.replace(/block\.timestamp/g, 'getTime()')
    return contractSrc
}

const preprocessContract = (contractSrc) => {

    contractSrc = contractSrc.replace(/contract (\S+)/g, 'contract $1_parsed')

    contractSrc = addTimestampSupport(contractSrc)
    /*if (DISABLE_REVERTS) {
        contractSrc = disableReverts(contractSrc)
    }

    // Soliditypp doesn't handle tx.origin well
    if (TX_ORIGIN_TO_MSG_SENDER) {
        contractSrc = contractSrc.replace(/tx\.origin/g, 'msg.sender')
    }

    if (ALLOW_DISABLE) {
        contractSrc = allowDisable(contractSrc)
    }*/

    return contractSrc
}

const transpileContract = (path) => {
    let contractSrc = fs.readFileSync(path, { encoding : 'utf-8' })
    contractSrc = preprocessContract(contractSrc)

    const newPath = path.replace('.sol', '_parsed.sol')

    fs.writeFileSync(newPath, contractSrc, { encoding : 'utf-8' })
}

transpileContract('./contracts/BasePool.sol')
transpileContract('./contracts/Controller.sol')
