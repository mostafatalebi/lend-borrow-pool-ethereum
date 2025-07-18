import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
      version: "0.8.28",
      settings: {
        optimizer: {
          enabled: true,
        }
      },
      
    },
    paths: {
        sources: "./contracts"
    }      
};

export default config;
