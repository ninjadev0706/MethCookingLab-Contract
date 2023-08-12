module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const purchaseCap = ethers.utils.parseEther(String(333340));

  await deploy("MethCookingLab", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy

    from: deployer,
    args: ["0xc0f2430ba47372d0a6beca8a74acc6179230e986", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"],
    log: true,
  });

};

module.exports.tags = ["MethCookingLab"];
