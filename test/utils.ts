
import { Types } from "../typechain-types/contracts/AssetManager.v1.sol/AssetManager";

export function GetEvent(contract: any, receipt: any, eventName: string) : any {
    const ev = receipt.logs.find(log => { 
        try {
            const parsed = contract.interface.parseLog(log);
            if (parsed != null ){
                return parsed.name === eventName;
            }
        } catch {
            return;
        }

        }
    )
    return ev;
  }