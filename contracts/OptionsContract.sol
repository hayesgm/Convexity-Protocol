pragma solidity 0.5.10;

import "./OptionsFactory.sol";
import "./UniswapFactoryInterface.sol";
import "./UniswapExchangeInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract OptionsContract is ERC20 {
    using SafeMath for uint256;
    struct Repo {
        uint256 collateral;
        uint256 putsOutstanding;
        address payable owner;
    }

    UniswapFactoryInterface constant UNISWAP_FACTORY = UniswapFactoryInterface(
        0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95
    );

    Repo[] repos;

    uint256 totalCollateral; // denominated in collateralType, depending on underlying type need to be able to handle decimal places
    uint256 totalUnderlying; // denominated in underlyingType, depending on underlying type need to be able to handle decimal places
    uint32 penaltyFee; //(need 4 decimal places → egs. 45.55% needs to be storable)
    uint128 numRepos;
    mapping (address => uint256) amtExercised;
    bool optionType; // 1 is American / 0 is European
    uint256 windowSize; // amt of seconds before expiry tht a person has to exercise
    uint256 totalExercised; // total collateral withdrawn from contract balance

    uint16 public collateralizationRatio = 16; //(need to be able have 1 decimal place)

    IERC20 public collateral;
    UniswapExchangeInterface public collateralExchange;
    IERC20 public underlying;
    uint256 public strikePrice; //depending on underlying type need to be able to handle decimal places
    IERC20 public strikeAsset;
    IERC20 public payout;
    UniswapExchangeInterface public payoutExchange;
    uint256 public expiry;



    constructor(
        IERC20 _collateral,
        IERC20 _underlying,
        uint256 _strikePrice,
        IERC20 _strikeAsset,
        IERC20 _payout,
        uint256 _expiry
    )
        public
    {
        collateral = _collateral;
        if (!isETH(collateral)) {
            // go to Uniswap for the appropriate exchange
            collateralExchange = UniswapExchangeInterface(
                UNISWAP_FACTORY.getExchange(address(collateral))
            );

            // if address(0), uniswap doesn't have an exchange
            if (address(collateralExchange) == address(0)) {
                revert("No collateral exchange");
            }
        }

        underlying = _underlying;
        strikePrice = _strikePrice;
        strikeAsset = _strikeAsset;
        payout = _payout;
        if (!isETH(payout)) {
            // same as above for collateral
            payoutExchange = UniswapExchangeInterface(
                UNISWAP_FACTORY.getExchange(address(payout))
            );

            if (address(payoutExchange) == address(0)) {
                revert("No payout exchange");
            }
        }

        expiry = _expiry;
    }

    function addETHCollateral(uint256 _repoNum) public payable returns (uint256) {
        return _addCollateral(_repoNum, msg.value);
    }

    function addERC20Collateral(uint256 _repoNum, uint256 _amt) public returns (uint256) {
        require(collateral.transferFrom(msg.sender, address(this), _amt));

        return _addCollateral(_repoNum, _amt);
    }

    function exercise(uint256 _pTokens) public {
        // 1. before exercise window: revert
        require(now >= expiry - windowSize, "Too early to exercise");
        require(now < expiry, "Beyond exercise time");

        // 2. during exercise window: exercise
        /// 2.1 ensure person calling has enough pTokens
        /// 2.2 check they have corresponding number of underlying
        /// 2.3 transfer in underlying and pTokens
        /// 2.4 sell enough collateral to get strikePrice * pTokens number of payoutTokens
        //// 2.4.1 func on uniswap which performs sell and transfer to given user


        // 3. after: TBD (but don't allow exercise)
    }

    function getReposByOwner(address owner) public view returns (uint[] memory) {
        //how to write this in a gas efficient way lol
    }

    function getRepos() public view returns (uint[] memory) {
        //how to write this in a gas efficient way lol
        return repos;
    }

    function getReposByIndex(uint256 repoIndex) public view returns (Repo) {
        return repos[repoIndex];
    }


    function isETH(IERC20 _ierc20) public pure returns (bool) {
        return _ierc20 == IERC20(0);
    }

    function _addCollateral(uint256 _repoNum, uint256 _amt) private returns (uint256) {
        require(now < expiry, "Options contract expired");

        Repo storage repo = repos[_repoNum];

        repo.collateral = repo.collateral.add(_amt);

        totalCollateral = totalCollateral.add(_amt);

        return repo.collateral;
    }
    function openRepo() public returns (uint) {
        uint repoIndex = repos.push(Repo(0, 0, msg.sender)) - 1 ; //the length
        return repoIndex;
    }

    function issueOptionTokens (uint256 repoIndex, uint256 numTokens) public {
        //check that we're properly collateralized to mint this number, then call _mint(address account, uint256 amount)
        return;
    }

    function burnPutTokens(uint256 repoIndex, uint256 amtToBurn) public {
        _burn(amtToBurn);
        repos[repoIndex].putsOutstanding -= amtToBurn;
    }

    function transferRepoOwnership(uint256 repoIndex, address newOwner) public {
        require(repos[repoIndex].owner == msg.sender, "Cannot transferRepoOwnership as non owner");
        repos[repoIndex].owner = newOwner;
    }

    function removeCollateral(uint256 repoIndex, uint256 amtToRemove) public {
        //check that we are well collateralized enough to remove this amount of collateral
    }




}
