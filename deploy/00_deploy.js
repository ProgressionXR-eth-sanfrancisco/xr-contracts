module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log(`Deploying contracts with the account: ${deployer}`);

  // 1. Deploy USDC mock contract or use existing one
  const usdcAddress = "0x309222b7833D3D0A59A8eBf9C64A5790bf43E2aA";

  // 2. Deploy HealthGains Contract
  const healthGains = await deploy("HealthGains", {
    from: deployer,
    args: [usdcAddress],
    log: true,
  });

  console.log(`HealthGains deployed at: ${healthGains.address}`);
};
