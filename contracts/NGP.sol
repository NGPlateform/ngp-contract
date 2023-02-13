//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract NGP is ERC20Upgradeable {
    struct MintInfo {
        address user;
        string number;
        uint256 updateTs;
        uint256 withdrawTs;
    }

    uint256 public daySupply;

    mapping(address => mapping(string=>MintInfo)) public userMints;

    mapping(string => address[]) public userApplys;
 
    mapping(string => uint256) public degreeHeats;

    mapping(address => string[]) public userNumbers;

    mapping(address => uint256)  public withdrawAmount;

    mapping(address => uint256) public unWithDrawAmount;

    mapping(address => uint256)  public rankWithdrawAmount; 

    mapping(address => bool) private minters;

    uint256 private spendNonce;

    mapping(address => bool) private isOwner;

    address[] private owners;

    uint256 private required;

    uint256 public  genesisTs;

    uint256 public activeMinters;

    uint256 public activeNumbers;

    uint256 public claimMints;

    uint256 public maxMeshHeats;

    uint256 public destructions;

    uint256 public  SECONDS_IN_DAY;

    struct StakeInfo {
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
    }

    uint256 public apy;

    uint256 public activeStakes;
    uint256 public totalNGPStaked;

    uint256 public totalEarn;

    mapping(address => StakeInfo) public userStakes;

    mapping(uint256 => uint256) public dayClaims;

    mapping(uint256 => bool) public dayClaimed;

    uint256 public treasuryValue;

    address public FoundationAddr;
 
    mapping(address => uint256) public stakeValues;

    //当日铸造NGP
    mapping(uint256 => uint256) public dayReceived;

    //当日质押NGP
    mapping(uint256 => uint256) public dayStaked;

    //当日解锁NGP
    mapping(uint256 => uint256) public dayUnStaked;

    event ClaimMint(address user,string number,uint256 time);

    event ClaimMintReward(address user,string number,uint256 time);

    event Staked(address indexed user, uint256 amount, uint256 term);

    event Withdrawn(address indexed user, uint256 amount, uint256 reward);

    event DegreeHeats(string number,uint256 heat);

    modifier isOnlyOwner {
        require(isOwner[msg.sender],"not owner");
        _;
    }

    function initialize(address[] calldata _owners,uint256 _apy,address _foundationAddr) external initializer {
        __ERC20_init("EARTH Token","EARTH");
        for (uint i = 0; i < _owners.length; i++) {
            //onwer should be distinct, and non-zero
            address _owner  = _owners[i];
            if (isOwner[_owner] || _owner == address(0x0)) {
                revert();
            }
           
            isOwner[_owner] = true;
            owners.push(_owner);
        }

        required = _owners.length/2 + 1;

        SECONDS_IN_DAY = 3_600 * 24;

        genesisTs = block.timestamp;

        apy = _apy;

        FoundationAddr = _foundationAddr;
    }

    //进行NGP的mint,需要传入编号
    //1. 同一个坐标范围，一个钱包地址只能绑定一次
    //2. 如果用户申明的网格已被其它用户申明占领过的话，需要燃烧
    function claimMint(string memory _number) external {
        MintInfo memory mintInfo = userMints[msg.sender][_number];

        require(mintInfo.updateTs == 0, "mNGP: Mint already in progress");

        uint256 _len = userApplys[_number].length;
        if( _len != 0) {
            uint256 _amount = degreeHeats[_number] / 10;
            destructions += _amount;

            _burn(msg.sender, _amount);
        }else{
            activeNumbers++;
        }

        mintInfo.number = _number;
        mintInfo.user = msg.sender;
        mintInfo.updateTs = block.timestamp;
        mintInfo.withdrawTs = block.timestamp;
        userMints[msg.sender][_number] = mintInfo;

        for(uint256 i = 0;i < userApplys[_number].length;i++){
            address _user = userApplys[_number][i];
            uint256 _day = (block.timestamp - userMints[_user][_number].withdrawTs) / SECONDS_IN_DAY;
            uint256 _withAmount =  _day * 6667 / _len;

            //用户当日的网格挖矿收益一直未被领取的话，将每过24小时衰减一次，每次衰减50%。
            _withAmount =  _withAmount * (2 - 1/(2 ** (_day - 1)));
            userMints[_user][_number].withdrawTs = block.timestamp;

            withdrawAmount[_user] += _withAmount;
        }

        userApplys[_number].push(msg.sender);

        //平均收益值: 864,000 / 12,960,000,0 = 0.0006667
        uint256 _n = userApplys[_number].length;

        uint256 _degreeHeats = 6667 * (106 ** _n / 100 ** _n);

        degreeHeats[_number]  = _degreeHeats;

        emit DegreeHeats(_number,_degreeHeats);

        if(_degreeHeats > maxMeshHeats) {
            maxMeshHeats = _degreeHeats;
        }
        
        userNumbers[msg.sender].push(_number);

        if(!minters[msg.sender]) {
            activeMinters++;

            minters[msg.sender] = true;
        }

        uint256 _today = block.timestamp / SECONDS_IN_DAY; 
        if(!dayClaimed[_today-1] && block.timestamp >= genesisTs + SECONDS_IN_DAY * 3) {
            treasuryValue += ((6667 - dayClaims[_today-2]) + (129600000 - activeNumbers) * 6667) * 10 ** 11;

            dayClaimed[_today-1] = true;
        }

        claimMints++;

        emit ClaimMint(msg.sender,_number,block.timestamp);
    }

    //_amount:是线下计算的80%部分的奖励 + 2部分的奖励
    function claimMintReward(address _user,uint256 _amount,uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) public isOnlyOwner  {
        require(validSignature(_user,vs, rs, ss), "invalid signatures");
        spendNonce = spendNonce + 1;

        uint256 _totalAmount = 0;

        uint256 _today = block.timestamp / SECONDS_IN_DAY; 

        //每天10%部分收益
        for(uint256 i = 0;i < userNumbers[_user].length;i++){
            string memory _number = userNumbers[_user][i];
            uint256 _len = userApplys[_number].length;

            uint256 _day = (block.timestamp - userMints[_user][_number].withdrawTs) / SECONDS_IN_DAY;

            uint256 _value = _day * 6667 /_len;

            if(_day >= 1) {
                dayClaims[_today-1] += _value;
            }

            //用户当日的网格挖矿收益一直未被领取的话，将每过24小时衰减一次，每次衰减50%。
            _totalAmount +=  _value * (2 - 1/(2 ** (_day - 1)));

            userMints[_user][_number].withdrawTs = block.timestamp;

            emit ClaimMintReward(msg.sender,_number,block.timestamp);
        }

        if(!dayClaimed[_today-1] && block.timestamp >= genesisTs + SECONDS_IN_DAY * 3) {
            uint256 _tValue = ((6667 - dayClaims[_today-2]) + (129600000 - activeNumbers) * 6667) * 10 ** 11;
            treasuryValue += _tValue;

            mint(FoundationAddr, _tValue/5);

            dayClaimed[_today-1] = true;
        }

        //10%部分
        //_reward有个精度，10 ** 11,0.0006667个
        uint256 _reward = (_totalAmount + withdrawAmount[_user]) * 10 /100 * 10 ** 11;

        uint256 _unReward = (_totalAmount + withdrawAmount[_user]) * 90 /100;
        unWithDrawAmount[msg.sender] = _unReward;

        mint(_user,_reward + _amount );

        withdrawAmount[_user] = 0;


    }

    function stake(uint256 amount, uint256 term) external {
        require(balanceOf(msg.sender) >= amount, "NGP: not enough balance");
        require(amount > 0, "NGP: amount > 0");
        require(term  >= 1, "NGP: term >= 1"); 
        require(userStakes[msg.sender].amount == 0, "NGP: stake exists"); // 已经质押过了

        // burn staked NGP
        _burn(msg.sender, amount);  // 烧掉一些 token 
        // create NGP Stake
        _createStake(amount, term);   // 创建质押数据  

        uint256 _today = (block.timestamp - genesisTs) / SECONDS_IN_DAY; 

        dayStaked[_today] += amount;

        emit Staked(msg.sender, amount, term);
    }

    function withdraw() external {
        StakeInfo memory userStake = userStakes[msg.sender];
        require(userStake.amount > 0, "NGP: no stake exists");
        // 计算质押奖励
        uint256 ngpReward = _calculateStakeReward(
            userStake.amount,
            userStake.term,
            userStake.maturityTs
        );

        uint256 unLockValue = userStake.amount + ngpReward;

        uint256 _today = (block.timestamp - genesisTs) / SECONDS_IN_DAY; 

        stakeValues[msg.sender] += ngpReward;

        totalEarn += ngpReward;

        activeStakes--;
        totalNGPStaked -= userStake.amount;

        dayUnStaked[_today] += unLockValue;

        mint(msg.sender, unLockValue);
        emit Withdrawn(msg.sender, userStake.amount, ngpReward);
        delete userStakes[msg.sender];
    }

    function _calculateStakeReward(
        uint256 amount,
        uint256 term,
        uint256 maturityTs
    ) private view returns (uint256) {
        if (block.timestamp > maturityTs) { 
            uint256 rate = apy * term;   // apy*天数*1000/365 
            return (amount * rate) / 10000;   // 质押的数量 * rate / 100_000_000 
        }
        return 0;
    }

    function _createStake(uint256 amount, uint256 term) private {
        userStakes[msg.sender] = StakeInfo({
            term: term,        // 天数
            maturityTs: block.timestamp + term * SECONDS_IN_DAY, // 到期时间
            amount: amount  // 数量
        });

        activeStakes++;     // 活跃质押者数量
        totalNGPStaked += amount; // 总的质押数量
    }

    function validSignature(address _sender,uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) public view returns (bool) {
        require(vs.length == rs.length,"vs.length == rs.length");
        require(rs.length == ss.length,"rs.length == ss.length");
        require(vs.length <= owners.length,"vs.length <= owners.length");
        require(vs.length >= required,"vs.length >= required");
        bytes32 message = _messageToRecover(_sender);
        address[] memory addrs = new address[](vs.length);
        for (uint i = 0; i < vs.length; i++) {
            //recover the address associated with the public key from elliptic curve signature or return zero on error
            addrs[i] = ecrecover(message, vs[i]+27, rs[i], ss[i]);
        }
       
        require(_distinctOwners(addrs),"_distinctOwners");
        return true;
    }

    function _messageToRecover(address _sender) private view returns (bytes32) {
        bytes32 hashedUnsignedMessage = generateMessageToSign(_sender);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
    }

    function generateMessageToSign(address _sender) private view returns (bytes32) {
        //the sequence should match generateMultiSigV2 in JS
        bytes32 message = keccak256(abi.encodePacked(_sender,block.chainid,spendNonce));
        return message;
    }

    function _distinctOwners(address[] memory addrs) private view returns (bool) {
        if (addrs.length > owners.length) {
            return false;
        }
        for (uint i = 0; i < addrs.length; i++) {
            if (!isOwner[addrs[i]]) {
                return false;
            }
            //address should be distinct
            for (uint j = 0; j < i; j++) {
                if (addrs[i] == addrs[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function getSpendNonce() external view returns (uint256) {
        return spendNonce;
    }

    function addSpendNonce() external  {
        spendNonce++;
    }  

    function getMeshData() view external returns(uint256 userCounts,uint256 launchData,uint256 totalMinted,uint256 liquidSupply) {
        userCounts = activeMinters;
        launchData = (block.timestamp - genesisTs) / SECONDS_IN_DAY;
        totalMinted = totalSupply();
        liquidSupply = totalMinted - balanceOf(address(this));
    }

    function getMeshDashboard() view external returns (uint256 participants,uint256 totalclaimMints,uint256 claimedMesh,uint256 maxHeats,uint256 sinceGenesis) {
        participants = activeMinters;
        totalclaimMints = claimMints;
        claimedMesh = activeNumbers;
        maxHeats = maxMeshHeats;
        sinceGenesis = (block.timestamp - genesisTs) / SECONDS_IN_DAY;
    }

    function getEarthDashboard() view external returns (uint256 _totalSupply,uint256 liquidSupply,uint256 destruction,uint256 totalStaked,uint256 treasury,uint256 foundation) {
        _totalSupply = totalSupply();
        liquidSupply = totalMinted - balanceOf(address(this));
        destruction = destructions;
        totalStaked = totalNGPStaked;
        treasury = treasuryValue;
        foundation = balanceOf(FoundationAddr);
    }

    function getStakeInfo(address _user) view external returns (uint256 tvl,uint256 revenue,uint256 earned,uint256 claimable,uint256 totalApy,uint256 staked,uint256 totalEarnValue,uint256 offEarthStake) {
        tvl = totalNGPStaked * 1/5;
        revenue = totalEarn * 1/5;
        earned = totalEarn;
        if(userStakes[_user].maturityTs >= block.timestamp) {
            claimable = userStakes[_user].amount;
        }else{
            claimable = 0;
        }

        totalApy = apy;

        staked = userStakes[_user].amount;

        totalEarnValue = stakeValues[_user];
        //当前质押锁定EARTH数量 / 已经累计铸造出来的EARTH总数量。
        offEarthStake = totalNGPStaked /  ERC20Upgradeable(totalSupply).totalSupply();
    } 

    function mint(address user,uint256 amount) private {
        uint256 _today = (block.timestamp - genesisTs) / SECONDS_IN_DAY; 

        dayReceived[_today] += amount;
        _mint(user, amount);
    }

    function getNetworkEvents() view external returns(uint256 _genesisTs,uint256[] memory _received,uint256[] memory _staked,uint256[] memory _unstaked) {
        uint256 _today = (block.timestamp - genesisTs) / SECONDS_IN_DAY; 
        _received = new uint256[](_today);
        _staked = new uint256[](_today);
        _unstaked = new uint256[](_today);

        _genesisTs = genesisTs;

        for(uint256 i = 0;i < _today;i++){
            _received[i] = dayReceived[i];
            _staked[i] = dayStaked[i];
            _unstaked[i] = dayUnStaked[i];
        }
    }

    function MintGNP(address user,uint256 amount) public {
        _mint(user, amount);
    }

    function getStakeTime(address user) view external returns(uint256 ts) {
        if(userStakes[user].amount == 0){
            ts = 0;
        }

        ts = userStakes[user].maturityTs;
    } 
}