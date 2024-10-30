"Provides checksums for bundler gem files"

# Update with:
# curl -sSf https://rubygems.org/api/v1/versions/bundler.json | jq 'map({key: .number, value: .sha}) | from_entries' | grep -vE '\.pre|\.rc|\.beta'

BUNDLER_CHECKSUMS = {
    "2.5.22": "763f30d598ee58742eea29285875435ea722218d4df149de35bce37c02ce968e",
    "2.5.21": "203d645e5f6daa60bbfb4cccb1a7d4aba8171674e00bc28724284740f8d9effb",
    "2.5.20": "83bccb5ccc456e347089aa05318ecd27bb9840caa64ed16c1703b50d49b0ab94",
    "2.5.19": "f856615c98070b70e58a69bc82882416498d19cb325fd18322da727385e0163f",
    "2.5.18": "042439fa8a5a2a64c37df8e4f6be5cd98d3f8fd5bcf511a1858b4878ef408a31",
    "2.5.17": "c4ef7050367e22f28e7928eb95ba055d111c2c4cd398de2ba8f6ab1532e46d3a",
    "2.5.16": "87ba0338f40d5928a79b1ab067867a36cde58135d08b63267ef639795b95983a",
    "2.5.15": "614280f031ff8d9adec0446b5cafda0103a2486520d556f9fc14d18762c48613",
    "2.5.14": "4b4be1b062ec3c9fbf7fe36d669c72187aa6f0d310077bfdfe6f2c26696c5544",
    "2.5.13": "e43d6dd6dfd707ea085ffcdef2255b94656c1e6d124ac867760eb3c44e2bd2bd",
    "2.5.12": "57e55d69ce82eec540abf19b60f89db54e9c02e42e8483d2f843143b438907f2",
    "2.5.11": "dd784bfe53834b39a56e642dbc6e1eca19a2e6454e4d53994cb7298005ac4c2e",
    "2.5.10": "7ad6beed8fa49a79a592029f773f2492b9f4ef916d8a72cee4e2d104e5b6faad",
    "2.5.9": "e2b61325be359bce54eb0fed88404efe67e5e1f8003d34a221841e3b765aec06",
    "2.5.8": "18bbe29d0c26d6453197f94da75fafafd56a003337b6e2d2f6e443af609a20c2",
    "2.5.7": "0dfe04a1f0ec13cdbc579f724cd0f7fa17437db07b89a41f5997e20bf4a8340e",
    "2.5.6": "1a1f21d1456e16dd2fee93461d9640348047aa2dcaf5d776874a60ddd4df5c64",
    "2.5.5": "13c7fe269030e2a6402a654c06deff01aef674ced649db3be98b5503a080a462",
    "2.5.4": "f7b9f08c47e8c665613a668aa1b633df63f818b99183cee4b797704a816edefe",
    "2.5.3": "249cd075ac4f335ae70f788c9be0f4c188093a4da7d05bd53be2baef3f25e7cb",
    "2.5.2": "4f41bc156623cc0a99bbf21a03475982bfa27dad6d8d31aa93b90752e7a255db",
    "2.5.1": "6b63f1bb4aedcde7fa2be3b309db7cb897170e9b4c09ad30314d50001b37b117",
    "2.5.0": "8952136f2d10816c73def0e8bc4b25c8f3fec9d4a58d571516e923b7cd2ed6c2",
    "2.4.22": "747ba50b0e67df25cbd3b48f95831a77a4d53a581d55f063972fcb146d142c5f",
    "2.4.21": "017ae71a7b0a3024c614e344cd0cc56a16cb34afc53ada1899fb379d26624c91",
    "2.4.20": "744b2b1951da613af2af6854f7c1f9e16dd90b4b66cd9af1a27a9f448c761bee",
    "2.4.19": "334dc796438384732fdf19bfa2f623753b7ed85160d08ce1f20009984cefb362",
    "2.4.18": "b6f7d27121d49874a69c9194d4f8ef556b2390cceec41635ccf4f3c58069f70e",
    "2.4.17": "d8457a5e76c9d153d4bb0fd1ffd2a3f58fbf090cb3448b9bd7a021d13f0e44ad",
    "2.4.16": "16346e067d589d95200a80f33c511b30b8a2e8901288525b2d3292e2175e9d69",
    "2.4.15": "14cd9e409c90cb55319878fefb3be5a8bcfc7433b14115de8523b2b5f734aeaa",
    "2.4.14": "94824acd510adf40f8dcee6ad18c09f85712c89c468a3dae5a5c47fa69487c72",
    "2.4.13": "11653aa5ae507c6dbd55bf7e9be8926d99afac9b6c0c08d3a1938afeb3e75a8b",
    "2.4.12": "cb554cd4f8bf471d177937dfe6f52fee60ad70bb4aaf710d7270fa4a24dece4d",
    "2.4.11": "d0eb78e71face8c0e07c0566aee1862f886e1a066b8600177f694337b37c749b",
    "2.4.10": "b9806fa944063a6a8676a8f9ed4c7c776a36c3bc82f26c5760867a0285b4a121",
    "2.4.9": "6e2450061a11ad1c1b931551ed27ba60e9eacee148e25e1d73a67dd8944584d3",
    "2.4.8": "fe82d6f893f2173e13232926e2b9ceb6f67027c7f166bfc1e3d6ec7d9699a164",
    "2.4.7": "b1941d6405890fb3da1fcaacf8d0d64eee427776019ce18856cf863b13fd1fb9",
    "2.4.6": "308fe0d77c3934ca0743bf00275d4194a86e96ba1423ac4d3ea435f621f9d4ff",
    "2.4.5": "5af8faaf09666d59ccdf1a8e461f17bbc5c4e49badb2dcaee174659f8c87d44a",
    "2.4.4": "83003159591df67a6d311b5a65cfbef0f98965d20356bebac14bf5c62d4d3c9d",
    "2.4.3": "01f5f83f274535d821858937700a4a2f1b53c3c2fcb0b12f537638f67287c700",
    "2.4.2": "99850ec40587ee1bfb2a7e76d4e548f0fcb3a0edd3e8b18f263031034edbb91f",
    "2.4.1": "a6eb7847f55ad87e288eec3660870bef82ffb8a5c5f1b59dee5598f03bafb827",
    "2.4.0": "f2c9f1f6db7c6147ce72a6fd6f265eef129563464a582539bbb50f8daf40e2bd",
    "2.3.27": "dde4820453502e6cba55723d1376ccd6d2da049a7bbb922e3e7355cc7601034b",
    "2.3.26": "1ee53cdf61e728ad82c6dbff06cfcd8551d5422e88e86203f0e2dbe9ae999e09",
    "2.3.25": "fd81ec4635c4189b66fd0789537d5cb38b3810b70765f6e1e82dda15b97591ad",
    "2.3.24": "eaa2eb8c3892e870f979252b2196bd77eb551e1dbf3cdc4eb164ba01ec4438c4",
    "2.3.23": "c58ad486dccd7cddd7f6bf06a868fd77569e66470fa3316b93fd9cf685642b1f",
    "2.3.22": "bce7d907aa683ac8983d42da1a15170fd692c6504678ada0845ef4a2ecf4209e",
    "2.3.21": "faedc7ffc167a3c53b64c463da67b50d5be43804761de5a68dda344c21bfd1de",
    "2.3.20": "809277bc7ceb268e97a474b58b02dbefb8ddf59077f4618b70e2504ab81a047c",
    "2.3.19": "bb32b7d2c661f3f2120ee25112d39470f22295a575623782dcbfa32e18a81af1",
    "2.3.18": "c6b23829686f13709482286d58d6c35e312aba8ff7990db9309c4e8b55323351",
    "2.3.17": "1390f43ddb5b7d674aba25ccbf5c182d92e0c56fa28e637cc241084d70aaa88a",
    "2.3.16": "4d6fbda60cdfa44f14a9918ca5d4e91b10509be22c0c724cdbcdeefaf186f672",
    "2.3.15": "05b7a8a409982c5d336371dee433e905ff708596f332e5ef0379559b6968431d",
    "2.3.14": "2fae2925c22ae122b245416484373a139d57a3e123fe9baed98d407384ea803c",
    "2.3.13": "7ec5e5caa8d21f7af9c106bd9091a96fa9f32104ecfc0b5f50ff25edf8a42dfd",
    "2.3.12": "c3eea9e54f259ec283d35a0cc931778735f424b6b87b79f34830428a9fd0ba97",
    "2.3.11": "75e790ddf37071288648eff2781db2a139e246ada01d6f16b9ea6b5e83d7e899",
    "2.3.10": "d2281b20da6ee66f4a1aedf03c39eaaf106763bfafee42cb093e213d2cb33b66",
    "2.3.9": "55988ab920cfdec4a805750f70f9b01d1fc66d9b38ecd205f99957b474995b38",
    "2.3.8": "3011c4429ec443dcf8da0561f3981b15f1a9665ed956bdcf051688ce10a8f501",
    "2.3.7": "10ef366406e986d4b20ed4f41e448a2b315c1685a42733a9e45f98b62db8d841",
    "2.3.6": "394d3c75a8972228cec4844aebcf2c2e87bdc35de2e20bbad0f40d5900fa6194",
    "2.3.5": "2553cbd138b466bc56a3c724c5c28648dff8e2343b13a7c696cf9c2818c8d629",
    "2.3.4": "e7f97326c36a66df37328b6cf6185a4c72d1dae79dc0b0132bcb41e4debf2485",
    "2.3.3": "3252d36ac6d154776a278f0a2f7c47c5397adeb6fd636d21549285a9af7faf1d",
    "2.3.2": "d01ea5d25c7050d9dbc3af7958347db86075b918dd5f10cda61414e07915ec84",
    "2.3.1": "178a6164a50c40264a1eebd3ee28bae1a1bf7d59c5bdbd1ec88768ca6644b9d7",
    "2.3.0": "7533077b794e99ee2a830760ce06bdbf729788cd5734ca32a989f3b5eafeced1",
    "2.2.34": "07218cf3780efd9fe7c03d932d40cd3e5ffa56024d397880294b6ed52de667f6",
    "2.2.33": "0a6fd4db0d3d9232053d15f1d9062729ba86bae667367da2506b600a24f70654",
    "2.2.32": "a5fc106134ce2048fd46b68c10c8d1c296a9006a0ee473da7c5116def4a7fb6a",
    "2.2.31": "307c9a31c5ba920a527a2a5c2384674932df35a4e7405a67cef614403a2f132e",
    "2.2.30": "65d0c1668a9a4679bd7038e03e1ee97ca6a1474e8da0e1ed8fb0e199933e3f75",
    "2.2.29": "6f465e70baa7a7ecd6f67f7869b595c2f3e345e2ee4211fb4009dcf508c244ca",
    "2.2.28": "ae9022e6a845dc822635bd8884ea91a8f4c454cbff8ee7bc3114391a8525afe7",
    "2.2.27": "21d85c47937496b08b021df716b4eaa81e2223a04e8eba92ee9e767b9e1b3ed8",
    "2.2.26": "62d173a626d64cb516785a5cba13da4800dc50ceac19c30ad5267dea27f7f35d",
    "2.2.25": "422237ffbbf2ceb05e696df7abb1bd1a82b5b1823eb2aeb6193312a60c319d8d",
    "2.2.24": "c2f894a38a27de2635ed48f29bedb252c4160f99b3d773d54865790a71fd6cf4",
    "2.2.23": "ae71a19f1231d320a1f934243e6a4e3518cf63f97e2c0954b5fea3f46ed070ac",
    "2.2.22": "7e7a5490154b37eefa8940f50a33bae1e12657656a1b007c4144c80474fa86e2",
    "2.2.21": "3c8dc5e0cf66d385a9b33751e54986290d42023c5e1bba2b5df094917b6e234a",
    "2.2.20": "259ba486173d72a71df43fee8e3bc8dcb868c8a65e0c4020af3a6f13c3a57ff8",
    "2.2.19": "3258301b85495f427949d8d825926d817392cca653f05479eaa7845f71c08aa0",
    "2.2.18": "79c4e66022f7a6fd2457103db0c88872e0ee1e1eb7a5fc975e22b0d33aa9a6d4",
    "2.2.17": "7acaaf4fad8761124d3b575e54c22040ebe596d4d47f3e5f57290615e4e26dd5",
    "2.2.16": "ca808d98b472ba8632c643a3cd21e1dfc72a538842c4534ff212c34d4e3ab240",
    "2.2.15": "9295b52d6744076497b86a7dfe03ffa4599942f245558c98071b8a05e3535835",
    "2.2.14": "ae7a1756a3b51f2748e19cf4f51abe00e53f3091c0d824c9e39f6ac13be04336",
    "2.2.13": "d3f434e1ec75f212409b78000276b4b943feacf4c7c4f529d36965a0fe486e14",
    "2.2.12": "4e5c2a2e8acd916fdbfb008ad2d6afe44b2e9dc6789fb96447656ee0b4970488",
    "2.2.11": "4ea2e025ced4c8487ab5e25a80978e3973b870f9e1bfaffab2d5d4263537fdc7",
    "2.2.10": "5fb16a2f6fad0bcd8fb593a592bfdde083a7901afb440ffac46a1983b09bad93",
    "2.2.9": "b7aa885d7c90c34552488b83fa1b8f3ee75a813395d3548840270c4f5ad46198",
    "2.2.8": "6fc07402b9938fd86e735d21df03731d8afdc2ec3a5d39a984a2353b5753844b",
    "2.2.7": "859b9307182681262643eaf1f58973aac273748e6b96824b6db532de76b38db2",
    "2.2.6": "140ffb665029b029ce3afc1300c2c33aaaea1b6173e722279e021b28107e4893",
    "2.2.5": "1b8f19fb50cdc9d8b7e73cc460d814b6ec19602c1b3b0e16c00e5b41f0e8e5c1",
    "2.2.4": "ab9ce52d5c53dfcf4ecb9dc027f78dd1949dfcb5655b04a4c87fa1d91d878000",
    "2.2.3": "6acefda4aeb34cb3d69aff06affce10424d69f484402a9f7f5577e8c698070db",
    "2.2.2": "aa266aaa692c18a9ea7f12da7a5584c94de26e016a6b72520fb48c0c6649621e",
    "2.2.1": "a18869701feb1f54e50cfbb8acec219f5c0eb99bc11458cd8c17a2cfb0123ad9",
    "2.2.0": "65d7c3dc82651915d49a408769b6c5ccde8103b27a8b9be1c674899594613994",
    "2.1.4": "50014d21d6712079da4d6464de12bb93c278f87c9200d0b60ba99f32c25af489",
    "2.1.3": "9b9a9a5685121403eda1ae148ed3a34c86418f2a2beec7df82a45d4baca0e5d2",
    "2.1.2": "a3d89c9a7fbfe9364512cac10bc8dc4f9c370e41375c03cd36cad31eef6fb961",
    "2.1.1": "c20e3e7a18de9d99b5919eaaee4dbeecc55ffcbfd08e1807572a618f426fdfc2",
    "2.1.0": "b3a865af3c8e78cab4d663e087cef4aa79672aacd9defdf783f0f493e2a25c2e",
    "2.0.2": "4c2ae1fce8a072b832ac7188f1e530a7cff8f0a69d8a9621b32d1407db00a2d0",
    "2.0.1": "c7e38039993c9c2edc27397aef4a3370a4b35c7fae3d93e434e501c4bd7656ea",
    "2.0.0": "e21aaa1aff1414df064a627e7fcdb31c43e4a72820082f0153fdf8d6ba288f73",
    "1.17.3": "bc4bf75b548b27451aa9f443b18c46a739dd22ad79f7a5f90b485376a67dc352",
    "1.17.2": "b954038e22e232cc94feb323187e42194b4ed6e16a1712b37e5bd6018ec17635",
    "1.17.1": "cc9042aff791fb05dc037da8dc617bee3fb4d77d74c3d921c2f51c23f231b24a",
    "1.17.0": "a674b4a3e813b2902504a0ce9e84e9ba84979d59fd353362e541ed59ce4edecc",
    "1.16.6": "07b445ea98d39032d257016a971a0c0947556eea7855ce64970da2a82e098605",
    "1.16.5": "413f98ef094008a8528d44167c16b0739449bb605ff670d88014b30759971e1c",
    "1.16.4": "6d04e02370d3066af29c7ef254d43223c717631d9d0ec1b8da849f8036eef997",
    "1.16.3": "d89111fd6fcea3039df8f945a6be00988e29f32f9271ee35a14c7b83a36ced6a",
    "1.16.2": "3bb53e03db0a8008161eb4c816ccd317120d3c415ba6fee6f90bbc7f7eec8690",
    "1.16.1": "42b8e0f57093e1d10c15542f956a871446b759e7969d99f91caf3b6731c156e8",
    "1.16.0": "084e7ebe90cc5236520ad49d4c5d9f58b19a98751a249070296a5943f88adb74",
    "1.15.4": "fad17ea3a1c15df2f2a7fcea052b35ebeab0dc87906cd762470637bef8c98472",
    "1.15.3": "ae6860b754b0d06fdb2a0e67dfba99610a003aad27d76a0e77f9ff6b1badaa88",
    "1.15.2": "941ccbcde4749f5f89c42e726fe07fd0e96adcf9fe0e5ddebac3fae000e3f887",
    "1.15.1": "fa6ec48f94faffe4987f89b4b85409fd6a4ddce8d46f779acdc26d041eb200d7",
    "1.15.0": "2d22a3fa26b00a62a19fc29f805a6cdccedaf0e4a7ca55816c27e644b2fc04cd",
    "1.14.6": "f431206d5e89e803b7cf0dd232683eaec769ec168707e9b3d8297dba35137d40",
    "1.14.5": "7118d31f5ed7d6c8f9b767d511f6be9a48e257a816cebd702416a6afacd16518",
    "1.14.4": "dbcd7c05de13ff4a9ded7353fe761767e5777fe9c49d2f1420f50672cfaa4ec1",
    "1.14.3": "9d61c7d983b99eb0b16d64658b182e045bcdd74ef3b139e849777f780782dbfe",
    "1.14.2": "27abd62a2e01ca898479232c38ca6050d03194d1d460f908ac52eb1a2baecce9",
    "1.14.1": "90a2a220eb18f676def5a9e92aeb595445b9132ae2df5ffa5342e50de030ee56",
    "1.14.0": "ed0a8fe1fb0654a5971ef51e8754816be555494b667535ba285e8e4ff679319c",
    "1.13.7": "a9f0c8c5cf977cadce77e6185695d4a0b956a73569a5634b15b34cc07fdb7bab",
    "1.13.6": "fafd22dfed658ca0603f321bdd168ed709d7c682e61273b55637716459f2d0f7",
    "1.13.5": "360a0569469c725dbad8e618cf28deb57366123efef93a04518f427cb03ab93b",
    "1.13.4": "92729d3460ec5ed9bc8db04145c3f3373e4e8a994ecebc6fe0f5ab2814af9075",
    "1.13.3": "524092831a73e8d33d1030a2c6cb533f393e1e0573fa10ff1a0f2cbf57342555",
    "1.13.2": "a61f8a57781c01cabe5afa468164aee550b6d0b1238fc073cd7b80601df4fc15",
    "1.13.1": "cf1f6203db06531c7086d3fa3ca8c8e579b2cdd003dd7f4f5063607ef692eb09",
    "1.13.0": "0c779c47e2561b8bab7c12f82d9ca5d3b0c0a6f7839bacaf1ddec1c2218db929",
    "1.12.6": "2d15046557e079bb4a8d8ad69956a7f9bff8a14a5d75860e18781ce2d79f2deb",
    "1.12.5": "6c5e111b828de62d3b5d72d8ae0add77099a34059ede582f0de7c85479ec04e1",
    "1.12.4": "9010e3529ca5a1a5aa62969ae1b6997f485edd35cd0720e64dffad80321718a5",
    "1.12.3": "450afb1b440b959dc4897f63f28c999a929156211f07b5a5de9043ebef0212b9",
    "1.12.2": "5fffd46672fd7c5405cb8b29919b110ad37f3feb40cbc54b1779f593aebf5963",
    "1.12.1": "e3133b1a73d51d7adb9898e24ef07d84e479fb121b8f848320756db222ceaed0",
    "1.12.0": "5bca5421236b5467e33aa318d8eecfbb64f217c14913f299e8775f0513af29ba",
    "1.11.2": "c7aa8ffe0af6e0c75d0dad8dd7749cb8493b834f0ed90830d4843deb61906768",
    "1.11.1": "7ffed4f74a3f9b9222be04a3d3640443e235173887394176884269a4ea16cc96",
    "1.11.0": "7bbd63426fe89de6fc66adc19837fcf1f44bf29fb3018dc5a5dfff357aa4dedc",
    "1.10.6": "fb2933d12304cec75dac75b93a1cb045da026b291e6c65b09744ceb900769fee",
    "1.10.5": "cc166e24197d772d85a0788d1b2e2a12c0c5748e54c898abd275ad948ce17dfe",
    "1.10.4": "180284a435d24ef325d7897196032e64424a6efc1d7b0b6b13b61574d98ca2f5",
    "1.10.3": "9c2c7093468c763eeadad47dae9de4d7ed2e6f08e80a130d1b0d6db6a46608cc",
    "1.10.2": "83013b20b7894f3cbdf5faae16ff3364831b7cbe8762c1c85f748adf13fa9357",
    "1.10.1": "57e4b969ee140920b9d33d16b6cdffd9d0ed8302ecd1b0c5b4e6257938770e9e",
    "1.10.0": "114208e155f5d55d3ce1b420462a8352bd88e3018f8758eac046b9bbf425f685",
    "1.9.10": "1a6b2dc1e613e7a1e6dc5ef9852eee4b3965dc3edd4e39325226f550e676f779",
    "1.9.9": "8d789d1174de8a42673f13ecba6675c95e6585c79a9a166b4d8aeb9b4c09138b",
    "1.9.8": "cb5a70519a38449e4a3c1f9519c586e78611434178f0bf32a0a6e6d1aa78ec31",
    "1.9.7": "fb0803424f340e24b990da1815dc63b6f4a916b31f1b61c95226ba68b110258c",
    "1.9.6": "16ea402865debde4cb64e63f70a0f5bd464649a29ab256579a7ceb42cca45ee4",
    "1.9.5": "ff0e1058789b34e293a35187bfffce592dfecfc1f8664ca2b8e1732987380f5d",
    "1.9.4": "3890e20fea4fdc44e61cd1422b4272942fef2a43a62f469ff6b08e615f1328fa",
    "1.9.3": "db09bb06357f63b235f58836a8c434f4f55814b4bdeb0826aac9b2bd808a7aed",
    "1.9.2": "f327204a48106f5682c52e10c1954fb0289d97a2d8b420dfab31d6f3b05d6932",
    "1.9.1": "55a9d7e34133130614c4552886fa4a480a33fb44f2479ebbee3b6ea33d2888ab",
    "1.9.0": "e47a3ad1b37f4bb41d6a30bb5538288c0d1cb11caf6d86da2c653ddc78225c8e",
    "1.8.9": "a7609f3f1e5ba72b56f991b5b64492b8199461f5d836a82c665a55e036999acc",
    "1.8.8": "bb9c2d14433173eeb66c460ce9f1957385482ef55234fafb95e62de532f3dd1c",
    "1.8.7": "c12f7cbf2a486c432f569d26f06d1d78ee0a3c2fd6519989d81e08df2bb0da94",
    "1.8.6": "56c10559b334884ceb3998d5d150c06cf322bc2dca7cf578c8c4609a7d2ae2bc",
    "1.8.5": "bdd4b6d604cd81346d45f912eb6f70f06104b320bc85b5a10162ae99ffa9457e",
    "1.8.4": "3a17c8e4df1e96b59d292da8e4841545fc1cec2e079a71478cb9bd8e78a5a393",
    "1.8.3": "fa2eed66b1611ce9b5da896ff348c8c800f3e91d42797d6bfe091b72d1370de1",
    "1.8.2": "342da88174d60adbcb30217325c72f6974d812355dcd6fb3acc001dfcab4485e",
    "1.8.1": "177057a97e8709bb570c58bb7c89759a029e1ce618756951c8333ea18c380275",
    "1.8.0": "98522906ac94a4d78de6c724f3e1e201681c4397b359d87fd2f4a491798b74b6",
    "1.7.15": "bf491b71adafe39bf7396d143393d6b100bd441d8fcf0323d42a13893e1cf36b",
    "1.7.14": "04c6c3ee221fad57bea2841e01b6c879431e412d7b79c82234a9aea04920a166",
    "1.7.13": "a3c7f6fa006c62c88acd21655eaa31dd6731cdd5a77b826be23f9d17e728e78b",
    "1.7.12": "8250a219eaa28d5f14e24802540285d97a8eeff0dbe26ed6c9150b78cb902fb9",
    "1.7.11": "e70609caaa462e71ae29dcc236f73559c130d83fc4fc9c3e39f785df8bfea40b",
    "1.7.10": "3a5b029493afa2423bd3cdb340af54a807b96736be1b4282512cb122f4211b32",
    "1.7.9": "9579b8c55f850196ebf6940a10b34ceb54d7670317af9b969abe9f007300a2bd",
    "1.7.8": "0fa93d1836e81987d7ee7d8f3c86a6962e2a2d8eb77726568ea09ff90c5720b5",
    "1.7.7": "b0bdf77f8150d013bae6958df4be016c98c85da774aeab5a42f9533b469321a4",
    "1.7.6": "4c02fcdbc02253b5eed7b8bb7ee5ecad8f6774c8b2d43c7ec40ef58361cfce1d",
    "1.7.5": "8646f1b5b05aeee81b51d2b8a854b3b7451859a83b4cd5ccc6635a618208f9a4",
    "1.7.4": "09414b2dedd098bab278a46bd9a10b9cf6b409e06bb90f40ae001d60fe015388",
    "1.7.3": "d2cfd2cb30a14bbaab0cef7917d220d6285d6eaed024e445680b47c816592303",
    "1.7.2": "0c7a7c3db178597681a6c56462cf71f0f12dc8175bdf2fd38b8044bfe362caf5",
    "1.7.1": "02169ba6550960f0456c1825a0882641c553172abb2198c748f42514ebc29e90",
    "1.7.0": "32ac937d82bc7980011b6d1ae41ed215a415fef7ed2ed9a3721e251872c58b6d",
    "1.6.9": "413dfad0afe80ad5c666b36ae87c955e03dca0ef3b353db1a42fdba53b1a94cc",
    "1.6.8": "6e9cddf4d131d74b4210036ce4c86111f5a81fca367147c0a6e286deb7c7aa60",
    "1.6.7": "345e544c760bd383a1eb7eb913e815465cf5223549c5a0bf94fdf7d7e0e0540a",
    "1.6.6": "e5091199e486db925347f80f9a324ee3e235b46a917796cfef69e44653a77a26",
    "1.6.5": "14b42fa2beb54ddfa00d9fe4d7eb9fce1d3f0bced34c498417ba27bf8a039de8",
    "1.6.4": "c71be83c77dd79d08ce6b0df83857ff804b5023f85af892bc361f20802c0111f",
    "1.6.3": "57eb3d7a41d6fb1c99ef62f654b5a95a0736889ccedcf68af175d433dc4c4521",
    "1.6.2": "194ae4470a509341c1f8c79b53aab042b3d1f463bfeabdf914281d1bf926a74d",
    "1.6.1": "ab6e3b0bed298cb2a3320d521d38979b4f58415c27b8627cb8765793df8c94db",
    "1.6.0": "0b3affb2ed505ec3b04f58a883c44bfd2afc75988fbe7ee2a4e603a5d803531a",
    "1.5.3": "149c96a57c8c1f02c5e5c2d71f1d25f8b59f7d7f2b101106c0e217232c78bd27",
    "1.5.2": "e696038798bbe0a49f73eb08dfc7f57618bcaffc6ca4391d8e6ab28d7720fd41",
    "1.5.1": "53bbc1b911d60dc5eb581a02411a46028165dbba193e0c7c407a53bdc7ef288f",
    "1.5.0": "23ca9206ad22ee13ac162c826aaadd3733f4f56d2b0a6a04e12a58257d2658b9",
    "1.3.6": "2ba6a8ce2367b2e382b9691e6fba8089db40bb4bb88054ded1adf2616cba125f",
    "1.3.5": "08b89047f7b829f3e197a28fb1bde74c3f5cfea1552f99dfba237fee30eaffe4",
    "1.3.4": "12e291979824f8dd485825d9bd85fd33fda09c1a46ef8fc0cb145b68c361f9ed",
    "1.3.3": "919978d5b199ac24c6f0945849b6e4a4fa0b637fdd6c6299e755489fe627c23a",
    "1.3.2": "fbe574abd927b00a9e908e824c8a0e0b78d07cc1a80a8eaa247dc6bb6355bd97",
    "1.3.1": "459c3a9336ae91b8e1045a6e3ff94fe8c218e73141b3b6009d169190a676bbda",
    "1.3.0": "f723b7328abc90fd3cf406a6fdf193eb48ddba8d9303408b2d6ff193a0235a9b",
    "1.2.5": "7efe3e651e89ed092cb9178925e124af2300e8c8f778eaedb423a9f583bc8923",
    "1.2.4": "f4b53b7c060d732700ee60897372caa5e87f64230e0c1158346ff324ec52205d",
    "1.2.3": "9c6c3553a94b93a1664337ead705d73a410c54269a97c7084e2d800498f5c62d",
    "1.2.2": "aa15860bc6918acd8d38043266563ddce91eac81c22ff4c10ef837ebe9979df5",
    "1.2.1": "7093e4f750cf34b6051d765e7f86a88ebe4394921571532233f640f1a7ce6790",
    "1.2.0": "abdafd376d88d8823851d5396a522704014bf21d5ad80b802f97245b5fbab903",
    "1.1.5": "627270b2c18ff6747ea15427aaa5aec30c15718a3db27693d929fdbd431679bf",
    "1.1.4": "203f23d42f175f3a66e3c882821f207187bb2cdcbb86ff76ab2df700e624f28e",
    "1.1.3": "df5ce52b6229bae5cf2eabae71858ea7e735fa0e479b4d00cff1ee18c5f6e800",
    "1.1.2": "4bd9e56ca0a64e7069527997faa2f784cececfb6fadffd7b98652f22ce170b8c",
    "1.1.1": "fd5b79cf09648e13b759ea1c7be1830029d7be1efb2fe80620619cfedf099915",
    "1.1.0": "e1075ee2a6d1e6460d80ef1421db686e08885286bc3db9216f1abc7ee20d3a2d",
    "1.0.22": "c0e7285aa312240747b3a3b1de59786a04950a4240ec6c96b9d0efdd58d4ec43",
    "1.0.21": "4603cb044a1a7f78042692e866615fa7158d830066ffce075911bfbdcbf99d51",
    "1.0.20": "c38a0b5bfbd06655362815124e711cb68bf22af5e23e54c65f68cde5d986609b",
    "1.0.18": "abace9e70731ac1d3be808f6160a9540b80d23cd27e1a94077b3f95d57c4e167",
    "1.0.17": "c2351609c768eb981fbb748eddd3e7d1b9ab01e150941430f366f741a327ccb0",
    "1.0.15": "37f36b76cb19463738616f098c53610f654b0b246c8b72b3f9694cb28013d11f",
    "1.0.14": "1266f59adcf8a03607657b286268101d0bc2a67243cc480fa47d1a5eb8abc35a",
    "1.0.13": "4ad01020f6a25331761d821439ff15426c4726b71d347b8e8eda01d7e99dbff0",
    "1.0.12": "103fec97d369fd518a7556bc4cc597b69d609f723949439760ecd9b889e5e7cb",
    "1.0.11": "5f3e3ffd66bf8c2e66b5952b0dc856e4adaddd3f203789934c183d0accdb0fd6",
    "1.0.10": "ebe11eabeb9bd6272735240975800dddc347cbb48d9665d2b9c53d2dc752f501",
    "1.0.9": "f10e39eb283b231e51d5c304d32b82354e7dce45af33812f7422add8fb7ab1a4",
    "1.0.7": "761c0b957f794a442d1385755292abb1ba636960632a485ebf06c0a99208f6ca",
    "1.0.5": "2cd8c7aa1c11637ed688ed8591695fdf355f7b418088759880487b2ad1482749",
    "1.0.3": "2ad0c0bca6a74de182279768ebf54c0cd8584b0841077f8ae884d0e64e9f2dd6",
    "1.0.2": "a62d9f7f21c975553dfbb8bc826a2f4ee86e98a996829e58441f528b73a3d1c4",
    "1.0.0": "60605563fcb6de38d088fd6416bee408405d365a608fdaec674339fc50d52f74",
    "0.9.26": "cfa4b309d005751b43dcfec7b569829faa38e1b5e332747a77eb97ff7c1c6b41",
    "0.9.25": "4a060d0071af200a8aac0e7747ef9db4d1d1dc44a6e3a5b0d0ad43454f833dad",
    "0.9.24": "ac9955cf23000e63534fc1ef940cef3f2df4eef0415b62fed1a8e1c78381fbb0",
    "0.9.23": "b342adf248d193cbb6c6d64d73b3fc9c0dce196c645cb685b3cf420740de7655",
    "0.9.22": "57bfcee38ab4ace7f70468d7c2559460505c1cab53b1642578efa899ec11607b",
    "0.9.21": "4447753858bd83101f1213fcecb60eec29b96bd18a40cff4714dd91d6f0a0464",
    "0.9.20": "941038390229510b086f98f04b9b217341193266076b8822a8a271f3439bc459",
    "0.9.19": "3be651ec7706f61ad611559844376c1f1be12d0ddd17d9c96ce341550d8bfc07",
    "0.9.18": "515b87628c46af6a8a4472294c8e07f2d1be307cb272cfbe49e1e94fd94bd25b",
    "0.9.17": "d7c68cb8f1f4e24d3552aed7bc67e850faa4c12ce81854811f0fd5ee78653eae",
    "0.9.16": "8686cde60bc94f9f9e5f06cc0a4166904bd8500d93f9090ee69b56288c0e7102",
    "0.9.15": "13d9022f853c17537ea4b3e6b396449ab60f1467d1e491b07a8b9707d34e09aa",
    "0.9.14": "c9b59efa22a24d959051b0fe566073ef64ab85baf6b2b37a2bc90c7fed00743d",
    "0.9.13": "d49388d19577375ff3460b34eee81aca2d673af8e700609f28dc7200a9b932e5",
    "0.9.12": "7d0111d78a452ddb7a72a44396d88ecf4c33deb9270e45927ec1b765271b19d6",
    "0.9.11": "1f0de01382509eb312c0624caecbf74ed88f6be6aa63a590ab039c8c88195fc8",
    "0.9.10": "f7356f065c8b1c1aa31ea0fab01d64617c40c13fbc5d99a6f41a0a006274febc",
    "0.9.9": "038bcd6b0d95eccba8caedcf6bcfac19188e37a09a6dd8dcb4c872c222fa4f44",
    "0.9.8": "9ab32b41c0a59fa40d0eb3465739768fa90e26a385058205b071373db77400af",
    "0.9.7": "68a2b32d6fccd7e8a5caaae21dd7e249fe4d4339d803bb0beb7e539bba2b09d0",
    "0.9.6": "bff7ba69061b5b8b75d6064bc55b72a8a9b2178add115137f427f083ce2d4261",
    "0.9.5": "a302a687b6dc726ad7837adccc5f149ed3a9f3477d0ecd64efb2524e54356daa",
    "0.9.4": "8c07153c4b4f8eb08405c6d8cb3ae4e778bf5349efdd876958df779b5c06fb25",
    "0.9.3": "905ed9228622dc24294ac7a415eaac0299b06909ad1b1232b0821ccfb0305fc6",
    "0.9.2": "d44280912d04f01823646c09047965c2d3c18b03cbe4e4d0ad158196bf1d4ee6",
    "0.9.1": "7bc0a8155eb9c487934ebe4189e299eae5582ad063028ec6c6b9ff85ccbb0a5f",
    "0.9.0": "b13a7dc0bc5dc278c8e5de0f7d899c6fd87841648205e64a9748080ae249ab7a",
    "0.8.1": "8dcdaec5f576e1ee58c5e5b2a73de7bfcd52183567a7fa16f63816465ac901ee",
    "0.8.0": "6c36833c591f45710008280e80c4ce02c372b9828fac32bcc74e71ae393e00ff",
    "0.7.2": "758a01f20e576607bfb28ab27f6163517baab3e1ab8b5594adf8551d0fa80445",
    "0.7.1": "6198a3990437309059ff0d746d2439014e707bfe5c7ee2aa4b6a6622e134d68b",
    "0.7.0": "f699a9be9b5fda5cab2eb15a8e0ce18991b0919bc2d1d1953c961b1efeff79fa",
    "0.6.0": "ed37a7e1a0e1c6c5ffec48a4dfe49bdde4e49a7dc98c2579c3f7f5ecb66bf673",
    "0.5.0": "f307e4114542163c1c0738380c46b252395024c9ed4261ca12ddf1982eb02da1",
    "0.4.1": "e9265ccb8c92eb64a530165449028791e30b27b8fbc302ac83b8d351f8ee90d4",
    "0.4.0": "fe921f0123736bf47ddbea0ea4714b6f5666fd5aa1929e2d916437b3bb028080",
    "0.3.1": "46ee4daadda796c1e9433b45015ff43f67ea47c8cf10e6f224ff5d87126d3302",
    "0.3.0": "c90db69e215d0caa267149111284bb35558cf9640bfa03c73317218397df2363",
}
