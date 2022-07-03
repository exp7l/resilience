const { exec } = require('child_process')
exec('forge build', (err, stdout, stderr) => {
  if (err)  throw err
  console.log(`stdout: ${stdout}`);
  console.log(`stderr: ${stderr}`);
})

