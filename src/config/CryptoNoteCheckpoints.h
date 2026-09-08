// Copyright (c) 2012-2017, The CryptoNote developers, The Bytecoin developers
//
// This file is part of Bytecoin.
//
// Bytecoin is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Bytecoin is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Bytecoin.  If not, see <http://www.gnu.org/licenses/>.

#pragma once

#include <cstddef>
#include <initializer_list>

namespace CryptoNote {
struct CheckpointData {
  uint32_t index;
  const char* blockId;
};

// Cleared: these were TurtleCoin's own checkpoints, tied to TurtleCoin's chain.
// They do not apply to this fork's chain and were causing every block past
// height 1 to be rejected as a checkpoint mismatch.
// TODO: as this chain grows and you're confident in its history, you can add
// your own checkpoints here (height, block hash) to protect against deep reorgs.
const std::initializer_list<CheckpointData> CHECKPOINTS = {
};
}
