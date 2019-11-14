'use strict';
var __awaiter =
  (this && this.__awaiter) ||
  function(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P
        ? value
        : new P(function(resolve) {
            resolve(value);
          });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator['throw'](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  };
var __generator =
  (this && this.__generator) ||
  function(thisArg, body) {
    var _ = {
        label: 0,
        sent: function() {
          if (t[0] & 1) throw t[1];
          return t[1];
        },
        trys: [],
        ops: []
      },
      f,
      y,
      t,
      g;
    return (
      (g = { next: verb(0), throw: verb(1), return: verb(2) }),
      typeof Symbol === 'function' &&
        (g[Symbol.iterator] = function() {
          return this;
        }),
      g
    );
    function verb(n) {
      return function(v) {
        return step([n, v]);
      };
    }
    function step(op) {
      if (f) throw new TypeError('Generator is already executing.');
      while (_)
        try {
          if (
            ((f = 1), y && (t = op[0] & 2 ? y['return'] : op[0] ? y['throw'] || ((t = y['return']) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done)
          )
            return t;
          if (((y = 0), t)) op = [op[0] & 2, t.value];
          switch (op[0]) {
            case 0:
            case 1:
              t = op;
              break;
            case 4:
              _.label++;
              return { value: op[1], done: false };
            case 5:
              _.label++;
              y = op[1];
              op = [0];
              continue;
            case 7:
              op = _.ops.pop();
              _.trys.pop();
              continue;
            default:
              if (!((t = _.trys), (t = t.length > 0 && t[t.length - 1])) && (op[0] === 6 || op[0] === 2)) {
                _ = 0;
                continue;
              }
              if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) {
                _.label = op[1];
                break;
              }
              if (op[0] === 6 && _.label < t[1]) {
                _.label = t[1];
                t = op;
                break;
              }
              if (t && _.label < t[2]) {
                _.label = t[2];
                _.ops.push(op);
                break;
              }
              if (t[2]) _.ops.pop();
              _.trys.pop();
              continue;
          }
          op = body.call(thisArg, _);
        } catch (e) {
          op = [6, e];
          y = 0;
        } finally {
          f = t = 0;
        }
      if (op[0] & 5) throw op[1];
      return { value: op[0] ? op[1] : void 0, done: true };
    }
  };
var __importDefault =
  (this && this.__importDefault) ||
  function(mod) {
    return mod && mod.__esModule ? mod : { default: mod };
  };
exports.__esModule = true;
var web3_utils_1 = require('web3-utils');
var bn_js_1 = __importDefault(require('bn.js'));
var level_rocksdb_1 = __importDefault(require('level-rocksdb'));
var preHashed_1 = require('./preHashed');
var fs_1 = __importDefault(require('fs'));
exports.EXIST_HASH = web3_utils_1.soliditySha3('exist');
exports.verifyProof = function(proof) {
  var path = '1' + proof.leaf.toString(2, proof.siblings.length);
};
/**
 * Sparse Merkle Tree implementation manages only the existence of nullifiers.
 */
var SparseMerkleTree = /** @class */ (function() {
  /**
   * Init a Sparse Merkle Tree
   * @param {number} depth
   * @param {Array} leaves
   */
  function SparseMerkleTree(depth, location) {
    this.depth = depth;
    if (!fs_1['default'].existsSync(location)) {
      fs_1['default'].mkdirSync(location);
    }
    this.nodes = level_rocksdb_1['default'](location + '/node');
    this.values = level_rocksdb_1['default'](location + '/values');
    this.leafPrefix = new bn_js_1['default'](1).shln(depth - 1);
  }
  SparseMerkleTree.prototype.root = function() {
    return __awaiter(this, void 0, void 0, function() {
      return __generator(this, function(_a) {
        switch (_a.label) {
          case 0:
            return [4 /*yield*/, this.getNode(new bn_js_1['default'](1))];
          case 1:
            return [2 /*return*/, _a.sent().toString()];
        }
      });
    });
  };
  // async exist(nullifier: BN): Promise<boolean> {
  // }
  // async getProof(nullifier: BN): Promise<Proof> {
  // }
  SparseMerkleTree.prototype.updateLeaf = function(leaf, val) {
    return __awaiter(this, void 0, void 0, function() {
      var leafNode, leafNodeValue;
      return __generator(this, function(_a) {
        switch (_a.label) {
          case 0:
            leafNode = this.leafPrefix.add(leaf);
            leafNodeValue = web3_utils_1.soliditySha3(val);
            // Store the value
            return [4 /*yield*/, this.put(web3_utils_1.soliditySha3(val), val.toString())];
          case 1:
            // Store the value
            _a.sent();
            // Update parent nodes
            return [4 /*yield*/, this.updateNode(leafNode, leafNodeValue)];
          case 2:
            // Update parent nodes
            _a.sent();
            return [4 /*yield*/, this.updateParentNode(leafNode, leafNodeValue)];
          case 3:
            _a.sent();
            return [2 /*return*/];
        }
      });
    });
  };
  SparseMerkleTree.prototype.updateParentNode = function(child, val) {
    return __awaiter(this, void 0, void 0, function() {
      var parentNode, hasRightSibilng, siblingIndex, sibling, parentHash;
      return __generator(this, function(_a) {
        switch (_a.label) {
          case 0:
            parentNode = child.shrn(1);
            if (!parentNode.isZero()) return [3 /*break*/, 1];
            // Arrived to the root. Stop the recursive calculation.
            return [2 /*return*/];
          case 1:
            hasRightSibilng = child.isEven();
            siblingIndex = child.add(hasRightSibilng ? new bn_js_1['default'](1) : new bn_js_1['default'](-1));
            return [4 /*yield*/, this.getNode(siblingIndex)];
          case 2:
            sibling = _a.sent().toString();
            parentHash = hasRightSibilng ? web3_utils_1.soliditySha3(val, sibling) : web3_utils_1.soliditySha3(sibling, val);
            // Update parent node hash value
            return [4 /*yield*/, this.updateNode(parentNode, parentHash)];
          case 3:
            // Update parent node hash value
            _a.sent();
            // Recursively update parents
            return [4 /*yield*/, this.updateParentNode(parentNode, parentHash)];
          case 4:
            // Recursively update parents
            _a.sent();
            _a.label = 5;
          case 5:
            return [2 /*return*/];
        }
      });
    });
  };
  SparseMerkleTree.prototype.updateNode = function(index, val) {
    return __awaiter(this, void 0, void 0, function() {
      var _this = this;
      return __generator(this, function(_a) {
        return [
          2 /*return*/,
          new Promise(function(resolve) {
            _this.nodes.put(index.toString(), val, function(err) {
              if (err) {
                // throw err;
                resolve(false);
              } else {
                resolve(true);
              }
            });
          })
        ];
      });
    });
  };
  SparseMerkleTree.prototype.put = function(key, val) {
    var _this = this;
    return new Promise(function(resolve) {
      _this.values.put(key, val, function(err) {
        if (err) {
          // throw err;
          resolve(false);
        } else {
          resolve(true);
        }
      });
    });
  };
  SparseMerkleTree.prototype.getNode = function(key) {
    var _this = this;
    return new Promise(function(resolve) {
      _this.nodes.get(key.toString(), function(err, val) {
        if (err) {
          if (err.name == 'NotFoundError') {
            var height = _this.depth - key.bitLength();
            resolve(preHashed_1.preHashed[height]);
          } else {
            throw err;
          }
        } else {
          resolve(val);
        }
      });
    });
  };
  return SparseMerkleTree;
})();
exports.SparseMerkleTree = SparseMerkleTree;
//# sourceMappingURL=index.js.map
