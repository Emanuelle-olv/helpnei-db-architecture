
// queryViews.ts
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const activeSponsoredOwners = await prisma.$queryRawUnsafe(`SELECT * FROM vw_active_sponsored_owners`);
  const allSponsoredOwners = await prisma.$queryRawUnsafe(`SELECT * FROM vw_all_sponsored_owners`);
  const storeImpact = await prisma.$queryRawUnsafe(`SELECT * FROM vw_store_impact`);
  const userImpact = await prisma.$queryRawUnsafe(`SELECT * FROM vw_user_impact`);
  const communityImpact = await prisma.$queryRawUnsafe(`SELECT * FROM vw_community_impact`);
  const totalImpactedUsers = await prisma.$queryRawUnsafe(`SELECT * FROM vw_total_impacted_users`);

  console.log({
    activeSponsoredOwners,
    allSponsoredOwners,
    storeImpact,
    userImpact,
    communityImpact,
    totalImpactedUsers
  });
}

main().finally(() => prisma.$disconnect());
