pragma solidity >= 0.6.0;

import { Hasher, RollUpLib } from "./RollUpLib.sol";

library MiMC {
    /**
     * @dev This is a dummy implementation for contract compilation
     * We'll use a generated library by circomlib instead of this dummy library
     * Please see
     * 1. migrations/2_deploy_mimc.js
     * 2. https://github.com/iden3/circomlib/blob/master/src/mimcsponge_gencontract.js
     */
    function MiMCSponge(uint256 in_xL, uint256 in_xR, uint256 in_k) external pure returns (uint256 xL, uint256 xR) {

    }
}

contract MiMCRollUpExample {
    using RollUpLib for Hasher;

    function rollUp(
        uint prevRoot,
        uint index,
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public pure returns (uint) {
        return mimcHasher().rollUp(prevRoot, index, leaves, initialSiblings);
    }

    function merkleProof(
        uint root,
        uint leaf,
        uint index,
        uint[] memory siblings
    ) public pure returns (bool) {
        return mimcHasher().merkleProof(root, leaf, index, siblings);
    }

    function merkleRoot(
        uint leaf,
        uint index,
        uint[] memory siblings
    ) public pure returns (uint) {
        return mimcHasher().merkleRoot(leaf, index, siblings);
    }

    function mimcHasher() internal pure returns (Hasher memory) {
        return Hasher(parentOf, preHashedZero());
    }

    function parentOf(uint256 left, uint256 right) public pure returns (uint256) {
        uint k = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint R = 0;
        uint C = 0;

        R = addmod(R, left, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        R = addmod(R, right, k);
        (R, C) = MiMC.MiMCSponge(R, C, 0);

        return R;
    }

    function preHashedZero() public pure returns (uint[] memory preHashed) {
        preHashed = new uint[](32);
        preHashed[0] = 0;
        preHashed[1] = 20636625426020718969131298365984859231982649550971729229988535915544421356929;
        preHashed[2] = 8234632431858659206959486870703726442454087730228411315786216865106603625166;
        preHashed[3] = 7985001422402102077350925203503698316627789269711557462970266825665867053007;
        preHashed[4] = 18097266179879782427361438755277450939722755112152115227098348943187633376449;
        preHashed[5] = 17881168164677037514367869548776650520965052851469330112398906502158797604517;
        preHashed[6] = 922786292280634969147910688433687283453311471541485803183285293828322638602;
        preHashed[7] = 14966121255901869775959970702197500594950233358407635238140938902275743163839;
        preHashed[8] = 15950129931660381885541753302118095863142450307256106174572389060872212753325;
        preHashed[9] = 16464761340879542328718857346548831929741065470370013028703745046966789709133;
        preHashed[10] = 11972762318876148250598407171878031197622371246897016172503915308401213732056;
        preHashed[11] = 7913827324380002912938758147218110935918449588532059556694800104640909434031;
        preHashed[12] = 14201520385210729827116219584168613816702847828183492080736088918213644443332;
        preHashed[13] = 19029732785687608713409092674238273944769768778346177735601630846367663862230;
        preHashed[14] = 9765633014970032282883326548708085452828117842858057778809593961683652391199;
        preHashed[15] = 9184608079226899602988566046323093647302956568088945904343867790799636834536;
        preHashed[16] = 11972349427600729437586536522854878181067516905509141792053080533995039240745;
        preHashed[17] = 10394791637867481933492192273905206106132537050796826353952753436720278057277;
        preHashed[18] = 21603873164014736077455707301636180846390167331483347051143483563452635839188;
        preHashed[19] = 10702670482623275757618147033467511205224846353145369471471007524354211067453;
        preHashed[20] = 15861152665456129634282768916620638578537083483837606944866798857777821896920;
        preHashed[21] = 20498343842312919518012756000146570792846156269878679339031468414543426339604;
        preHashed[22] = 1830896951362318606259478024712157567812426156885361939285043189241513771542;
        preHashed[23] = 19593719479653527472481203317703616094885816284937720002104363542485933650238;
        preHashed[24] = 4400797949327175975924960109125282147819957262566898155662911307280024014954;
        preHashed[25] = 12110156141937099244315908177282106282668918440691683058499110829441835163334;
        preHashed[26] = 9078765299217261770649815856048748276723416702111447408964712367427337145876;
        preHashed[27] = 7562744990849102147449876072614349025641829560411500310719361613167782076730;
        preHashed[28] = 21038753574403875854879370369349092756264613161113435884488912185237116714302;
        preHashed[29] = 18173414435841866346435646879016412700973102443995503160340118818770908449021;
        preHashed[30] = 1684117701874574052474687836292170148751601456481610409096174606023255461470;
        preHashed[31] = 15545313534057078925780542540989871893874743830293027221182247788840178762050;
    }
}

contract MiMCOPRUChallenge is MiMCRollUpExample {
    using RollUpLib for Hasher;

    uint public root;
    uint public index;
    constructor(uint _root, uint _index) public {
        root = _root;
        index = _index;
    }

    uint[] appended;

    function addItems(
        uint[] memory leaves,
        uint[] memory initialSiblings
    ) public returns (uint) {
        root = mimcHasher().rollUp(root, index, leaves, initialSiblings);
        index += leaves.length;
        for(uint i = 0; i < leaves.length; i++) {
            appended.push(leaves[i]);
        }
    }
}