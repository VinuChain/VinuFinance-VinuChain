export async function mochaGlobalSetup() {
    console.log(`Test environment is ready.`);
}
export const mochaGlobalTeardown = async () => {
    console.log('Test environment cleared.');
  };
