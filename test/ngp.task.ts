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

      let tran = await contrat.claimMint(1);
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

    task("NGP:getMeshData", "getMeshData").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [NGP:getMeshData]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let MeshData = await contrat.getMeshData();
      console.log("MeshData:", MeshData);
    });

    task("NGP:getMeshDashboard", "getMeshDashboard").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [NGP:getMeshDashboard]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let getMeshDashboard = await contrat.getMeshDashboard();
      console.log("MeshData:", getMeshDashboard);
    });

    task("NGP:getEarthDashboard", "getEarthDashboard").setAction(async ({}, _hre) => {
      logtools.logyellow("method == [NGP:getEarthDashboard]");
      await ContractInfo.LoadFromFile(_hre);

      let contrat = await ContractInfo.getContractProxy("NGP", "NGPProxy");

      let getEarthDashboard = await contrat.getEarthDashboard();
      console.log("MeshData:", getEarthDashboard);
    });
    

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
  }
}
