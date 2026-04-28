/**
 * Copyright (c) 2026, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import * as os from "os";
import * as path from "path";
import { DEFAULT_PROFILE, MI_PROFILE, SI_PROFILE, type SelectedProfileValue } from "@wso2/wi-core";

const INTEGRATOR_STATE_DIR = path.join(os.homedir(), ".wso2-integrator");
const SELECTED_PROFILE_STATE_FILE = path.join(INTEGRATOR_STATE_DIR, "selected-profile");

export function getSelectedProfileStateFilePath(): string {
    return SELECTED_PROFILE_STATE_FILE;
}

export function writeSelectedProfileState(profile: SelectedProfileValue): void {
    if (!existsSync(INTEGRATOR_STATE_DIR)) {
        mkdirSync(INTEGRATOR_STATE_DIR, { recursive: true });
    }
    writeFileSync(SELECTED_PROFILE_STATE_FILE, profile, "utf8");
}

export function readSelectedProfileState(): SelectedProfileValue | undefined {
    if (!existsSync(SELECTED_PROFILE_STATE_FILE)) {
        return undefined;
    }

    const profile = readFileSync(SELECTED_PROFILE_STATE_FILE, "utf8").trim();
    if (profile === DEFAULT_PROFILE || profile === MI_PROFILE || profile === SI_PROFILE) {
        return profile;
    }

    return undefined;
}
