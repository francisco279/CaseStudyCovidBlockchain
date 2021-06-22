const Migrations = artifacts.require("Migrations");
const Vaccine = artifacts.require("Vaccine");
const Reception = artifacts.require("Reception");
const Application = artifacts.require("Application");
const MetaCoin = artifacts.require("MetaCoin");
const Pre_vaccination = artifacts.require("Pre_vaccination");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Vaccine);
  deployer.deploy(Reception);
  deployer.deploy(Application);
  deployer.deploy(MetaCoin);
  deployer.deploy(Pre_vaccination);
};
