// SPDX-License-Identifier: BSD-3-Clause

import GlifiKit

@main
enum GlifiCLI {
    static func main() async {
        let service = GlifiStudioService()
        let status = await service.status()

        switch status {
        case .ready:
            print("GlifiCore pronto")
        }
    }
}
