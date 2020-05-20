export const expectCall = (name: string, delay = 2000) => {
  if(process.env.IS_TEST)
  {
    const timeoutKey = setTimeout(()=>{
      throw new Error(`Didn't get expected [${name}] call in ${delay} milliseconds`)
    }, delay)

    return () => clearTimeout(timeoutKey)
  }else {
    return undefined
  }
    // throw new Error(`You need to remove tests from non test environment. Test name: [${name}]`)
}
