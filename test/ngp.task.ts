import { BigNumber, ContractReceipt, ethers } from "ethers";
import { ContractInfo } from "../utils/util_contractinfo";
import { logtools } from "../utils/util_log";
import { task } from "hardhat/config";
import Web3 from "web3";
import "@nomiclabs/hardhat-etherscan";
import * as fs from "fs";

export module extNGP {
  export function RegTasks() {
    task("NGP:claimMint", "claimMint").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [NGP:claimMint]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let tran = await contrat.claimMint("E11394N2252");
      let recipt: ContractReceipt = await tran.wait();
      logtools.loggreen("result = [");
      logtools.loggreen("     hash = " + recipt.transactionHash);
      logtools.loggreen("     status = " + recipt.status);
      logtools.loggreen("]");
      logtools.logcyan(
        "矿工费" +
          ethers.utils.formatUnits(
            recipt.gasUsed.mul(5000000000),
            BigNumber.from("18")
          )
      );
    });

    task("NGP:mintNGP", "mintNGP")
      .addPositionalParam("account", "account")
      .addPositionalParam("amount", "amount")
      .setAction(async ({ account, amount }, _hre) => {
        logtools.logyellow("method == [NGP:mintNGP]");
        await ContractInfo.LoadFromFile(_hre);

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        amount = ethers.utils.parseEther(amount);
        let tran = await contrat.MintGNP(account, amount);
        let recipt: ContractReceipt = await tran.wait();
        logtools.loggreen("result = [");
        logtools.loggreen("     hash = " + recipt.transactionHash);
        logtools.loggreen("     status = " + recipt.status);
        logtools.loggreen("]");
        logtools.logcyan(
          "矿工费" +
            ethers.utils.formatUnits(
              recipt.gasUsed.mul(5000000000),
              BigNumber.from("18")
            )
        );
      });

    task("NGP:stake", "stake")
      .addPositionalParam("amount", "amount")
      .addPositionalParam("term", "term")
      .setAction(async ({ amount, term }, _hre) => {
        logtools.logyellow("method == [NGP:stake]");
        await ContractInfo.LoadFromFile(_hre);

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        amount = ethers.utils.parseEther(amount);
        let tran = await contrat.stake(amount, term);
        let recipt: ContractReceipt = await tran.wait();
        logtools.loggreen("result = [");
        logtools.loggreen("     hash = " + recipt.transactionHash);
        logtools.loggreen("     status = " + recipt.status);
        logtools.loggreen("]");
        logtools.logcyan(
          "矿工费" +
            ethers.utils.formatUnits(
              recipt.gasUsed.mul(5000000000),
              BigNumber.from("18")
            )
        );
      });

    task("NGP:claimMintReward", "claimMintReward").setAction(
      async ({}, _hre) => {
        logtools.logyellow("method == [NGP:claimMintReward]");
        await ContractInfo.LoadFromFile(_hre);

        const [owner, addr1] = await _hre.ethers.getSigners();

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        let private2 =
          "0xb1a82552591c92f41e7d3b5bcfa346f10815fb8b9e709e4fb63345705d45cc62";

        let resu1 = await Sign(owner.address, private1);

        //claimMintReward(address _user,uint256 _amount,uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss)
        let amount = ethers.utils.parseEther("1");
        let tran = await contrat.claimMintReward(owner.address, amount);

        let recipt: ContractReceipt = await tran.wait();
        logtools.loggreen("result = [");
        logtools.loggreen("     hash = " + recipt.transactionHash);
        logtools.loggreen("     status = " + recipt.status);
        logtools.loggreen("]");
        logtools.logcyan(
          "矿工费" +
            ethers.utils.formatUnits(
              recipt.gasUsed.mul(5000000000),
              BigNumber.from("18")
            )
        );
      }
    );

    task("NGP:getMeshData", "getMeshData").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [NGP:getMeshData]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let MeshData = await contrat.getMeshData();
      console.log("MeshData:", MeshData);
    });

    task("NGP:getMeshDashboard", "getMeshDashboard").setAction(
      async ({}, _hre) => {
        logtools.logyellow("method == [NGP:getMeshDashboard]");
        await ContractInfo.LoadFromFile(_hre);

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        let getMeshDashboard = await contrat.getMeshDashboard();
        console.log("MeshData:", getMeshDashboard);
      }
    );

    task("NGP:getEarthDashboard", "getEarthDashboard").setAction(
      async ({}, _hre) => {
        logtools.logyellow("method == [NGP:getEarthDashboard]");
        await ContractInfo.LoadFromFile(_hre);

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        let getEarthDashboard = await contrat.getEarthDashboard();
        console.log("MeshData:", getEarthDashboard);
      }
    );

    task("NGP:getStakeTime", "getStakeTime")
      .addPositionalParam("user", "user")
      .setAction(async ({ user }, _hre) => {
        logtools.logyellow("method == [NGP:getStakeTime]");
        await ContractInfo.LoadFromFile(_hre);

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        let MeshData = await contrat.getStakeTime(user);
        console.log("MeshData:", MeshData);
      });

    task("NGP:getNetworkEvents", "getNetworkEvents").setAction(
      async ({ user }, _hre) => {
        logtools.logyellow("method == [NGP:getNetworkEvents]");
        await ContractInfo.LoadFromFile(_hre);

        let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

        let NetworkEvents = await contrat.getNetworkEvents();
        console.log("NetworkEvents:", NetworkEvents);
      }
    );

    async function Sign(sender, privateKey) {
      let prefix = "\x19Ethereum Signed Message:\n32";

      let signingKey = new ethers.utils.SigningKey(privateKey);

      let newContract = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let spendNonce = await newContract.getSpendNonce();

      let messageHash = ethers.utils.keccak256(
        ethers.utils.solidityPack(
          ["address", "uint256", "uint256"],
          [sender, 5, spendNonce]
        )
      );

      console.log("spendNonce:", spendNonce);

      const msg = ethers.utils.keccak256(
        ethers.utils.solidityPack(["string", "bytes32"], [prefix, messageHash])
      );

      let signature = await signingKey.signDigest(msg);

      let { v, r, s } = signature;

      v = v - 27;

      return [v, r, s];
    }
  }
}
